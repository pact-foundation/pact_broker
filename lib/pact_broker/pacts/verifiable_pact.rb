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
    end
  end
end
