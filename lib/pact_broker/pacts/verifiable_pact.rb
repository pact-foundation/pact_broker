require 'delegate'

module PactBroker
  module Pacts
    class VerifiablePact < SimpleDelegator
      attr_reader :selectors, :pending, :pending_provider_tags, :non_pending_provider_tags, :wip

      # TODO refactor this constructor
      def initialize(pact, selectors, pending, pending_provider_tags = [], non_pending_provider_tags = [], overall_latest = false, wip = false)
        super(pact)
        @pending = pending
        @selectors = selectors
        @pending_provider_tags = pending_provider_tags
        @non_pending_provider_tags = non_pending_provider_tags
        @overall_latest = overall_latest
        @wip = wip
      end

      def overall_latest?
        @overall_latest
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
