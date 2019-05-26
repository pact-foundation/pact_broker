require 'delegate'

module PactBroker
  module Pacts
    class VerifiablePact < SimpleDelegator
      attr_reader :pending, :pending_provider_tags

      def initialize(pact, pending, pending_provider_tags = [])
        super(pact)
        @pending = pending
        @pending_provider_tags = pending_provider_tags
      end
    end
  end
end
