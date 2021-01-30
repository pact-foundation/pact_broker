require 'delegate'
require 'pact_broker/error'

module PactBroker
  module Pacts
    class VerifiablePact < SimpleDelegator
      attr_reader :selectors, :pending, :pending_provider_tags, :non_pending_provider_tags, :pending_provider_branch, :wip

      # TODO refactor this constructor
      def initialize(pact, selectors, pending, pending_provider_tags = [], non_pending_provider_tags = [], wip = false, pending_provider_branch = nil)
        super(pact)
        @pending = pending
        @selectors = selectors
        @pending_provider_tags = pending_provider_tags
        @non_pending_provider_tags = non_pending_provider_tags
        @pending_provider_branch = pending_provider_branch
        @wip = wip
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

        if pending_provider_branch != other.pending_provider_branch
          raise PactBroker::Error.new("Can't merge two verifiable pacts with different pending_provider_branch")
        end

        latest_pact = [self, other].sort_by(&:consumer_version_order).last.__getobj__()

        VerifiablePact.new(
          latest_pact,
          selectors + other.selectors,
          pending || other.pending,
          pending_provider_tags + other.pending_provider_tags,
          non_pending_provider_tags + other.non_pending_provider_tags,
          wip || other.wip,
          pending_provider_branch
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
