require 'pact_broker/repositories'
require 'pact_broker/api/decorators/verification_decorator'

module PactBroker

  module Verifications
    module Service

      extend self

      extend PactBroker::Repositories

      def next_number_for pact
        verification_repository.verification_count_for_pact(pact) + 1
      end

      def create next_verification_number, params, pact
        PactBroker.logger.info "Creating verification #{next_verification_number} for pact_id=#{pact.id} from params #{params}"
        verification = PactBroker::Domain::Verification.new
        PactBroker::Api::Decorators::VerificationDecorator.new(verification).from_hash(params)
        verification.number = next_verification_number
        verification.pact_id = pact.id
        verification.save
      end

      def errors params
        contract = PactBroker::Api::Contracts::VerificationContract.new(PactBroker::Domain::Verification.new)
        contract.errors
      end
    end
  end
end
