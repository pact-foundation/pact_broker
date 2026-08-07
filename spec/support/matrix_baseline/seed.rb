require "pact_broker/domain/pacticipant"

module MatrixBaseline
  # Builds a small microservice mesh: many pure consumers, fewer pure
  # providers, and a handful of middle-tier services that are both a
  # consumer and a provider. Each consumer publishes several versions so
  # latestby dedup has something to collapse, a subset of pacts is verified
  # (mixing success and failure), and a few versions are deployed to a
  # single environment.
  #
  # Deterministic names and an explicit set of anchor rows let the shape
  # catalogue reference specific, known-good rows.
  class Seed
    CONSUMER_COUNT = 50
    PROVIDER_COUNT = 15
    BOTH_COUNT = 8
    VERSIONS_PER_CONSUMER = 4
    DEPS_PER_CONSUMER = 3

    ANCHOR_CONSUMER = "consumer-app-01"
    ANCHOR_CONSUMER_VERSION = "1"
    ANCHOR_PROVIDER = "provider-service-01"
    ANCHOR_PROVIDER_VERSION = "1"
    ANCHOR_BOTH = "gateway-service-01"
    ENVIRONMENT = "production"
    BRANCH = "main"
    TAG = "prod"

    WIDE_CONSUMER = "wide-consumer-01"
    WIDE_CONSUMER_VERSION = "1"
    WIDE_PROVIDER_COUNT = 30

    def self.call(td)
      new(td).call
    end

    def initialize(td)
      @td = td
      @consumers = Array.new(CONSUMER_COUNT) { |i| format("consumer-app-%02d", i + 1) }
      @providers = Array.new(PROVIDER_COUNT) { |i| format("provider-service-%02d", i + 1) }
      @both = Array.new(BOTH_COUNT) { |i| format("gateway-service-%02d", i + 1) }
      @wide_providers = Array.new(WIDE_PROVIDER_COUNT) { |i| format("wide-provider-%02d", i + 1) }
      @downstream_pool = @providers + @both
      @verification_counter = 0
      @verify_pact_calls = 0
    end

    def call
      td.create_environment(ENVIRONMENT)

      anchor_downstream = build_anchor_consumer
      build_remaining_consumers
      build_gateway_consumers
      build_wide_consumer
      deploy_into_environment
      deploy_wide_providers_into_environment

      {
        consumers: @consumers,
        providers: @providers,
        both: @both,
        wide_providers: @wide_providers,
        environment: ENVIRONMENT,
        branch: BRANCH,
        tag: TAG,
        anchors: {
          consumer: ANCHOR_CONSUMER,
          consumer_version: ANCHOR_CONSUMER_VERSION,
          provider: ANCHOR_PROVIDER,
          provider_version: ANCHOR_PROVIDER_VERSION,
          both: ANCHOR_BOTH,
          downstream: anchor_downstream,
          wide_consumer: WIDE_CONSUMER,
          wide_consumer_version: WIDE_CONSUMER_VERSION,
        },
      }
    end

    private

    attr_reader :td

    # The anchor consumer's downstream services are pinned explicitly so
    # shapes can rely on exact names: the anchor provider, the anchor
    # both-service, and two more pure providers.
    def build_anchor_consumer
      downstream = [ANCHOR_PROVIDER, ANCHOR_BOTH, @providers[1], @providers[2]]

      td.create_pact_with_hierarchy(ANCHOR_CONSUMER, ANCHOR_CONSUMER_VERSION, downstream.first)
      td.create_verification(provider_version: ANCHOR_PROVIDER_VERSION, number: 1, success: true)
      td.create_verification(provider_version: next_verification_version, number: 2, success: false)

      downstream.drop(1).each do |dep|
        ensure_provider(dep)
        td.create_pact(json_content: pact_content(ANCHOR_CONSUMER, dep, "1"))
        verify_pact(ANCHOR_CONSUMER, dep)
      end

      republish_extra_versions(ANCHOR_CONSUMER, downstream)

      downstream
    end

    def build_remaining_consumers
      pool_size = @downstream_pool.size

      @consumers[1..].each_with_index do |consumer, offset|
        index = offset + 1
        start = (index * DEPS_PER_CONSUMER) % pool_size
        downstream = Array.new(DEPS_PER_CONSUMER) { |k| @downstream_pool[(start + k) % pool_size] }

        td.create_pact_with_hierarchy(consumer, "1", downstream.first)
        verify_pact(consumer, downstream.first)

        downstream.drop(1).each do |dep|
          ensure_provider(dep)
          td.create_pact(json_content: pact_content(consumer, dep, "1"))
          verify_pact(consumer, dep)
        end

        republish_extra_versions(consumer, downstream)
      end
    end

    # Each middle-tier service is also a consumer of a couple of pure
    # providers, so it genuinely appears on both sides of the graph.
    def build_gateway_consumers
      @both.each_with_index do |gateway, index|
        downstream = [@providers[(index * 2) % PROVIDER_COUNT], @providers[(index * 2 + 1) % PROVIDER_COUNT]]

        td.create_pact_with_hierarchy(gateway, "1", downstream.first)
        verify_pact(gateway, downstream.first)

        downstream.drop(1).each do |dep|
          ensure_provider(dep)
          td.create_pact(json_content: pact_content(gateway, dep, "1"))
          verify_pact(gateway, dep)
        end

        republish_extra_versions(gateway, downstream)
      end
    end

    # A consumer with many integrations, all resolvable through the environment.
    # This is the shape that makes the per-selector cost of the matrix query
    # visible: can-i-deploy against an environment infers one selector per
    # integrated pacticipant, and each becomes its own arm of the version-
    # resolution UNION.
    def build_wide_consumer
      td.create_pact_with_hierarchy(WIDE_CONSUMER, WIDE_CONSUMER_VERSION, @wide_providers.first)
      verify_pact(WIDE_CONSUMER, @wide_providers.first)

      @wide_providers.drop(1).each do |dep|
        ensure_provider(dep)
        td.create_pact(json_content: pact_content(WIDE_CONSUMER, dep, WIDE_CONSUMER_VERSION))
        verify_pact(WIDE_CONSUMER, dep)
      end
    end

    # Each wide provider gets a version in the environment so its inferred
    # selector resolves to a real version rather than to NULL_VERSION_ID.
    def deploy_wide_providers_into_environment
      @wide_providers.each do |provider|
        td.use_provider(provider)
        td.create_provider_version("deployed")
        td.create_deployed_version_for_provider_version(environment_name: ENVIRONMENT)
      end
    end

    # The final version of each consumer is tagged so tag-resolving selectors
    # have a target; every republished version sits on a branch so
    # branch-resolving selectors do too. Both resolve through different code
    # paths to a version-number selector.
    def republish_extra_versions(consumer, downstream)
      (2..VERSIONS_PER_CONSUMER).each do |n|
        td.use_consumer(consumer)
        td.create_consumer_version(n.to_s, branch: BRANCH)
        td.create_consumer_version_tag(TAG) if n == VERSIONS_PER_CONSUMER
        downstream.each do |dep|
          td.use_provider(dep)
          td.create_pact(json_content: pact_content(consumer, dep, n.to_s))
        end
      end
    end

    # Verifies the pact that was just created (relies on the builder's
    # current consumer/provider/pact context) with two verifications whose
    # results disagree, alternating which way round on each call.
    #
    # The alternation is driven by a per-call counter rather than
    # @verification_counter, which advances twice per call and so has an
    # invariant parity. What matters is the *second* verification: latestby
    # collapses to it, so it decides whether the pact reads as passing. Half
    # the pacts ending on a failure is what gives the success filter something
    # to exclude and lets can-i-deploy reach its failure path.
    def verify_pact(_consumer, _provider)
      @verify_pact_calls += 1
      latest_success = @verify_pact_calls.odd?

      td.create_verification(provider_version: next_verification_version, number: 1, success: !latest_success)
      td.create_verification(provider_version: next_verification_version, number: 2, success: latest_success)
    end

    # Points the builder's current provider at an existing pacticipant, or
    # creates one if this is the first time the name has been referenced.
    def ensure_provider(name)
      if PactBroker::Domain::Pacticipant.where(name: name).empty?
        td.create_provider(name)
      else
        td.use_provider(name)
      end
    end

    # Pact content must be deterministic, not merely unique. The builder's
    # random_json_content embeds a `rand` in the interaction path, which varies
    # the stored row's length and so the page count of the tables the matrix
    # queries scan — enough to move the buffer counts in the captured plans
    # between runs. Keying the content on the pact's own identity keeps every
    # pact distinct (they are deduplicated by content hash) while making the
    # bytes on disk the same on every run.
    def pact_content(consumer, provider, version)
      td.fixed_json_content(consumer, provider, "#{consumer}-#{provider}-#{version}")
    end

    def next_verification_version
      @verification_counter += 1
      format("v%d", @verification_counter)
    end

    def deploy_into_environment
      td.use_provider(ANCHOR_PROVIDER)
      td.use_provider_version(ANCHOR_PROVIDER_VERSION)
      td.create_deployed_version_for_provider_version(environment_name: ENVIRONMENT)

      [@providers[1], @providers[2]].each do |provider|
        td.use_provider(provider)
        td.create_provider_version("deployed")
        td.create_deployed_version_for_provider_version(environment_name: ENVIRONMENT)
      end

      td.use_provider(ANCHOR_BOTH)
      td.create_provider_version("deployed")
      td.create_deployed_version_for_provider_version(environment_name: ENVIRONMENT)

      td.use_consumer(ANCHOR_CONSUMER)
      td.use_consumer_version(ANCHOR_CONSUMER_VERSION)
      td.create_deployed_version_for_consumer_version(environment_name: ENVIRONMENT)
    end
  end
end
