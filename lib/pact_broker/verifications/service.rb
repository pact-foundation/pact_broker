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
        verification_repository.create(verification, pact)
      end

      def errors params
        contract = PactBroker::Api::Contracts::VerificationContract.new(PactBroker::Domain::Verification.new)
        contract.errors
      end

      def find_latest_verifications_for_consumer_version params
        verification_repository.find_latest_verifications_for_consumer_version params[:consumer_name], params[:consumer_version_number]
      end

      def find_latest_verification_for consumer, provider
        verification_repository.find_latest_verification_for consumer.name, provider.name
      end
    end
  end
end
