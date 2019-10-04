require 'pact_broker/services'
require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'pact_broker/integrations/integration'

module PactBroker
  module Integrations
    class Service
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging

      def self.find_all
        PactBroker::Integrations::Integration
          .eager(:consumer)
          .eager(:provider)
          .eager(latest_pact: :latest_verification)
          .all
          .sort { | a, b| b.latest_pact_or_verification_publication_date <=> a.latest_pact_or_verification_publication_date }
      end

      def self.delete(consumer_name, provider_name)
        consumer = pacticipant_service.find_pacticipant_by_name(consumer_name)
        provider = pacticipant_service.find_pacticipant_by_name(provider_name)
        # this takes care of the triggered webhooks and webhook executions
        pact_service.delete_all_pact_publications_between(consumer_name, and: provider_name)
        verification_service.delete_all_verifications_between(consumer_name, and: provider_name)
        pact_service.delete_all_pact_versions_between(consumer_name, and: provider_name)
        webhook_repository.delete_by_consumer_and_provider(consumer, provider)
        version_repository.delete_orphan_versions(consumer, provider)

        pacticipant_service.delete_if_orphan(consumer)
        pacticipant_service.delete_if_orphan(provider) unless consumer == provider
      end
    end
  end
end
