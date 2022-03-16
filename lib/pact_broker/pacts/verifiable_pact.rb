require "delegate"
require "pact_broker/error"

module PactBroker
  module Pacts
    class VerifiablePact < SimpleDelegator
      attr_reader :selectors, :pending, :pending_provider_tags, :non_pending_provider_tags, :provider_branch, :wip

      # rubocop: disable Metrics/ParameterLists
      # TODO refactor this constructor
      def initialize(pact, selectors, pending = nil, pending_provider_tags = [], non_pending_provider_tags = [], provider_branch = nil, wip = false)
        super(pact)
        @pending = pending
        @selectors = selectors
        @pending_provider_tags = pending_provider_tags
        @non_pending_provider_tags = non_pending_provider_tags
        @provider_branch = provider_branch
        @wip = wip
      end
      # rubocop: enable Metrics/ParameterLists

      def self.create_for_wip_for_provider_branch(pact, selectors, provider_branch)
        new(pact, selectors, true, [], [], provider_branch, true)
      end

      def self.create_for_wip_for_provider_tags(pact, selectors, pending_provider_tags)
        new(pact, selectors, true, pending_provider_tags, [], nil, true)
      end

      def self.deduplicate(verifiable_pacts)
        verifiable_pacts
          .group_by { | verifiable_pact | [verifiable_pact.consumer_name, verifiable_pact.pact_version_sha] }
          .values
          .collect { | verifiable_pact | verifiable_pact.reduce(&:+) }
      end

      def pending?
        pending
      end

      def wip?
        wip
      end

      def + other
        if pact_version_sha != other.pact_version_sha
          raise PactBroker::Error.new("Can't merge two verifiable pacts with different pact content")
        end

        if provider_branch != other.provider_branch
          raise PactBroker::Error.new("Can't merge two verifiable pacts with different provider_branch")
        end

        if consumer_name != other.consumer_name
          raise PactBroker::Error.new("Can't merge two verifiable pacts with different consumer names")
        end

        latest_pact = [self, other].sort_by(&:consumer_version_order).last.__getobj__()

        VerifiablePact.new(
          latest_pact,
          selectors + other.selectors,
          pending || other.pending,
          pending_provider_tags + other.pending_provider_tags,
          non_pending_provider_tags + other.non_pending_provider_tags,
          provider_branch,
          wip || other.wip
        )
      end

      def <=> other
        if self.consumer_name != other.consumer_name
          return self.consumer_name <=> other.consumer_name
        else
          return self.consumer_version.order <=> other.consumer_version.order
        end
      end

      def consumer_version_order
        __getobj__().consumer_version.order
      end
    end
  end
end
