require 'delegate'

module PactBroker
  module Pacts
    class VerifiablePact < SimpleDelegator
      attr_reader :selectors, :pending, :pending_provider_tags, :non_pending_provider_tags, :wip

      # TODO refactor this constructor
      def initialize(pact, selectors, pending, pending_provider_tags = [], non_pending_provider_tags = [], wip = false)
        super(pact)
        @pending = pending
        @selectors = selectors
        @pending_provider_tags = pending_provider_tags
        @non_pending_provider_tags = non_pending_provider_tags
        @wip = wip
      end

      def pending?
        pending
      end

      def wip?
        wip
      end

      def <=> other
        if self.consumer_name != other.consumer_name
          return self.consumer_name <=> other.consumer_name
        else
          return self.consumer_version.order <=> other.consumer_version.order
        end
      end
    end
  end
end
