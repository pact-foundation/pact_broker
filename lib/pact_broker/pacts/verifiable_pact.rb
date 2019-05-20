require 'delegate'

module PactBroker
  module Pacts
    class VerifiablePact < SimpleDelegator
      attr_reader :pending

      def initialize(pact, pending)
        super(pact)
        @pending = pending
      end
    end
  end
end
