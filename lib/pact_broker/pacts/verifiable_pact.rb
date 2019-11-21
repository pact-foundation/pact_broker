require 'delegate'

module PactBroker
  module Pacts
    class VerifiablePact < SimpleDelegator
      attr_reader :pending, :pending_provider_tags, :non_pending_provider_tags, :head_consumer_tags, :wip

      # TODO refactor this constructor
      def initialize(pact, pending, pending_provider_tags = [], non_pending_provider_tags = [], head_consumer_tags = [], overall_latest = false, wip = false)
        super(pact)
        @pending = pending
        @pending_provider_tags = pending_provider_tags
        @non_pending_provider_tags = non_pending_provider_tags
        @head_consumer_tags = head_consumer_tags
        @overall_latest = overall_latest
        @wip = wip
      end

      def consumer_tags
        head_consumer_tags
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
