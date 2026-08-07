require "pact_broker/matrix/unresolved_selector"

module MatrixBaseline
  # The representative request catalogue for the matrix seed. Each shape
  # crosses an axis that changes the query plan: selector cardinality,
  # selector type, latestby, limit, and the matrix-vs-can-i-deploy path.
  #
  # Two shapes deliberately issue almost no SQL of their own. The success
  # filter is applied in Ruby over the materialised rows
  # (Repository#find), and ignore selectors are applied by RowIgnorer after
  # the query, so `success_filter` currently emits SQL identical to
  # `single_selector_version` and `can_i_deploy_ignore` adds only the lookup
  # that resolves the ignored name. They earn their place by pinning that:
  # if either filter is ever pushed down into the query, these shapes are
  # where it shows up.
  class Shapes
    Shape = Struct.new(:id, :label, :kind, :selectors, :options)

    # rubocop:disable Metrics/MethodLength
    def self.call(seed)
      anchors = seed.fetch(:anchors)
      providers = seed.fetch(:providers)
      both = seed.fetch(:both)
      environment = seed.fetch(:environment)
      branch = seed.fetch(:branch)
      tag = seed.fetch(:tag)

      consumer = anchors.fetch(:consumer)
      consumer_version = anchors.fetch(:consumer_version)
      provider = anchors.fetch(:provider)
      provider_version = anchors.fetch(:provider_version)
      downstream = anchors.fetch(:downstream)
      middle_tier = anchors.fetch(:both)
      wide_consumer = anchors.fetch(:wide_consumer)
      wide_consumer_version = anchors.fetch(:wide_consumer_version)

      sel = ->(**attrs) { PactBroker::Matrix::UnresolvedSelector.new(**attrs) }

      [
        Shape.new(
          "single_selector_version", "1 selector, version-specified", :matrix,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version)],
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "single_selector_name_only", "1 selector, name-only", :matrix,
          [sel.(pacticipant_name: consumer)],
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "two_selectors_version", "2 selectors, version-specified", :matrix,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version),
           sel.(pacticipant_name: provider, pacticipant_version_number: provider_version)],
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "five_selectors", "5 selectors", :matrix,
          [sel.(pacticipant_name: consumer)] + downstream.map { |d| sel.(pacticipant_name: d) },
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "large_n_selectors", "large-N selectors", :matrix,
          [sel.(pacticipant_name: consumer)] + (providers + both).map { |p| sel.(pacticipant_name: p) },
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "can_i_deploy_latest", "can-i-deploy, 1 selector + latest, no limit", :can_i_deploy,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version)],
          { latestby: "cvp", latest: true }
        ),
        Shape.new(
          "can_i_deploy_environment", "can-i-deploy --to-environment", :can_i_deploy,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version)],
          { latestby: "cvpv", environment_name: environment }
        ),
        Shape.new(
          "can_i_deploy_environment_large_n", "can-i-deploy --to-environment for a service with many integrations", :can_i_deploy,
          [sel.(pacticipant_name: wide_consumer, pacticipant_version_number: wide_consumer_version)],
          { latestby: "cvpv", environment_name: environment }
        ),
        Shape.new(
          "no_latestby_every_row", "no-latestby (EveryRow)", :matrix,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version)],
          { limit: "100" }
        ),
        Shape.new(
          "success_filter", "with success filter", :matrix,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version)],
          { latestby: "cvpv", success: [true], limit: "100" }
        ),
        Shape.new(
          "middle_tier_matrix", "single selector on a service that is both consumer and provider", :matrix,
          [sel.(pacticipant_name: middle_tier)],
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "branch_selector", "1 selector, latest from branch", :matrix,
          [sel.(pacticipant_name: consumer, branch: branch, latest: true)],
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "tag_selector", "1 selector, latest with tag", :matrix,
          [sel.(pacticipant_name: consumer, tag: tag, latest: true)],
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "can_i_deploy_ignore", "can-i-deploy with an ignored pacticipant", :can_i_deploy,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version)],
          { latestby: "cvp", latest: true, ignore_selectors: [sel.(pacticipant_name: provider)] }
        ),
      ]
    end
    # rubocop:enable Metrics/MethodLength
  end
end
