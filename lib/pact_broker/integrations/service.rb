require 'pact_broker/services'
require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'pact_broker/integrations/integration'
require 'pact_broker/db/models'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Integrations
    class Service
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging

      def self.find_all
        # The only reason the pact_version needs to be loaded is that
        # the Verification::PseudoBranchStatus uses it to determine if
        # the pseudo branch is 'stale'.
        # Because this is the status for a pact, and not a pseudo branch,
        # the status can never be 'stale',
        # so it would be better to create a Verification::PactStatus class
        # that doesn't have the 'stale' logic in it.
        # Then we can remove the eager loading of the pact_version
        PactBroker::Integrations::Integration
          .eager(:consumer)
          .eager(:provider)
          .eager(latest_pact: [:latest_verification, :pact_version])
          .eager(:latest_verification)
          .all
          .sort { | a, b| b.latest_pact_or_verification_publication_date <=> a.latest_pact_or_verification_publication_date }
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

        pacticipant_service.delete_if_orphan(consumer)
        pacticipant_service.delete_if_orphan(provider) unless consumer == provider
      end

      def self.delete_all
        # TODO move all these into their own repositories
        PactBroker::DB.each_integration_model do | model |
          if PactBroker::Repositories::Helpers.postgres?
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
    end
  end
end
