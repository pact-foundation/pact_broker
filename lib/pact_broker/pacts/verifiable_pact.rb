require 'delegate'

module PactBroker
  module Pacts
    class VerifiablePact < SimpleDelegator
      attr_reader :pending, :pending_provider_tags, :head_consumer_tags

      def initialize(pact, pending, pending_provider_tags = [], head_consumer_tags = [], overall_latest = false)
        super(pact)
        @pending = pending
        @pending_provider_tags = pending_provider_tags
        @head_consumer_tags = head_consumer_tags
        @overall_latest = overall_latest
      end

      def consumer_tags
        head_consumer_tags
      end

      def overall_latest?
        @overall_latest
      end
    end
  end
end
