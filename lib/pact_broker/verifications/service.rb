require 'pact_broker/repositories'
require 'pact_broker/api/decorators/verification_decorator'
require 'pact_broker/verifications/summary_for_consumer_version'
require 'pact_broker/logging'
require 'pact_broker/hash_refinements'
require 'wisper'

module PactBroker

  module Verifications
    module Service

      extend self

      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging
      using PactBroker::HashRefinements
      extend Wisper::Publisher

      def next_number
        verification_repository.next_number
      end

      def create next_verification_number, params, pact, event_context
        logger.info "Creating verification #{next_verification_number} for pact_id=#{pact.id}", payload: params.reject{ |k,_| k == "testResults"}
        verification = PactBroker::Domain::Verification.new
        provider_version_number = params.fetch('providerApplicationVersion')
        PactBroker::Api::Decorators::VerificationDecorator.new(verification).from_hash(params)
        verification.wip = params.fetch('wip')
        verification.number = next_verification_number
        verification = verification_repository.create(verification, provider_version_number, pact)

        broadcast_events(verification, pact, event_context)

        verification
      end

      def delete(verification)
        webhook_service.delete_all_webhook_related_objects_by_verification_ids(verification.id)
        verification_repository.delete(verification.id)
      end

      def errors params
        contract = PactBroker::Api::Contracts::VerificationContract.new(PactBroker::Domain::Verification.new)
        contract.validate(params)
        contract.errors
      end

      def find params
        verification_repository.find(params.fetch(:consumer_name), params.fetch(:provider_name), params.fetch(:pact_version_sha), params.fetch(:verification_number))
      end

      def find_latest_for_pact(pact)
        verification_repository.find_latest_for_pact(pact)
      end

      def find_by_id id
        PactBroker::Domain::Verification.find(id: id)
      end

      def find_latest_verifications_for_consumer_version params
        verification_repository.find_latest_verifications_for_consumer_version params[:consumer_name], params[:consumer_version_number]
      end

      def find_latest_verification_for consumer, provider, tag = nil
        verification_repository.find_latest_verification_for consumer.name, provider.name, tag
      end

      def find_latest_verification_for_tags consumer_name, provider_name, consumer_version_tag_name, provider_version_tag_name
        verification_repository.find_latest_verification_for_tags(consumer_name, provider_name, consumer_version_tag_name, provider_version_tag_name)
      end

      def search_for_latest consumer_name, provider_name
        verification_repository.search_for_latest(consumer_name, provider_name)
      end

      def verification_summary_for_consumer_version params
        verifications = find_latest_verifications_for_consumer_version(params)
        pacts = pact_service.find_by_consumer_version(params)
        SummaryForConsumerVersion.new(verifications, pacts)
      end

      def delete_all_verifications_between(consumer_name, options)
        verification_repository.delete_all_verifications_between(consumer_name, options)
      end

      private

      def broadcast_events(verification, pact, event_context)
        event_params = {
          pact: pact,
          verification: verification,
          event_context: event_context.merge(provider_version_tags: verification.provider_version_tag_names)
        }

        broadcast(:provider_verification_published, event_params)
        if verification.success
          broadcast(:provider_verification_succeeded, event_params)
        else
          broadcast(:provider_verification_failed, event_params)
        end
      end
    end
  end
end
