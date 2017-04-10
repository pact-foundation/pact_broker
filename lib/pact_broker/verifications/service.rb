require 'pact_broker/repositories'

module PactBroker

  module Verifications
    module Service

      extend self

      extend PactBroker::Repositories

      def next_number_for pact

      end

      def create next_verification_number, params, pact

      end

      def errors params
        contract = PactBroker::Api::Contracts::VerificationContract.new(PactBroker::Domain::Verification.new)
        contract.errors
      end
    end
  end

end
