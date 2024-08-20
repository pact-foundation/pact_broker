require "pact_broker/services"
require "pact_broker/repositories"
require "pact_broker/logging"
require "pact_broker/integrations/integration"
require "pact_broker/db/models"
require "pact_broker/repositories/scopes"

module PactBroker
  module Integrations
    class Service
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging
      extend PactBroker::Repositories::Scopes

      def self.find_all(filter_options = {}, pagination_options = {}, eager_load_associations = [])
        integration_repository.find(filter_options, pagination_options, eager_load_associations)
      end

      # Callback to invoke when a consumer contract, verification result (or provider contract in Pactflow) is published
      # @param [PactBroker::Domain::Pacticipant] consumer or nil
      # @param [PactBroker::Domain::Pacticipant] provider
      def self.handle_contract_data_published(consumer, provider)
        integration_repository.create_for_pact(consumer.id, provider.id)
        integration_repository.set_contract_data_updated_at(consumer, provider)
      end


      # Callback to invoke when a batch of contract data is published (eg. the publish contracts endpoint)
      # @param [Array<Object>] where each object has a consumer and a provider
      def self.handle_bulk_contract_data_published(objects_with_consumer_and_provider)
        integration_repository.create_for_pacts(objects_with_consumer_and_provider)
        integration_repository.set_contract_data_updated_at_for_multiple_integrations(objects_with_consumer_and_provider)
      end

      def self.delete(consumer_name, provider_name)
        consumer = pacticipant_service.find_pacticipant_by_name!(consumer_name)
        provider = pacticipant_service.find_pacticipant_by_name!(provider_name)
        # this takes care of the triggered webhooks and webhook executions
        pact_service.delete_all_pact_publications_between(consumer_name, and: provider_name)
        verification_service.delete_all_verifications_between(consumer_name, and: provider_name)
        pact_service.delete_all_pact_versions_between(consumer_name, and: provider_name)
        webhook_repository.delete_by_consumer_and_provider(consumer, provider)
        version_repository.delete_orphan_versions(consumer, provider)
        integration_repository.delete(consumer.id, provider.id)
        pacticipant_service.delete_if_orphan(consumer)
        pacticipant_service.delete_if_orphan(provider) unless consumer == provider
      end

      def self.delete_all
        # TODO move all these into their own repositories
        PactBroker::DB.each_integration_model do | model |
          if PactBroker::Dataset::Helpers.postgres?
            logger.info("Truncating ", model.table_name)
            model.truncate(cascade: true)
          else
            logger.info("Deleting all from ", model.table_name)
            # Mysql adapter needs to support cascade truncate
            # https://travis-ci.org/pact-foundation/pact_broker/jobs/633050220#L841
            # https://travis-ci.org/pact-foundation/pact_broker/jobs/633053228#L849
            model.dataset.delete
          end
        end
      end

      def self.find_for_provider(provider)
        scope_for(PactBroker::Integrations::Integration).where(provider_id: provider.id).eager(:consumer).eager(:provider).all.sort
      end
    end
  end
end
