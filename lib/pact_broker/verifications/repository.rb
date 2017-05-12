require 'sequel'
require 'pact_broker/domain/verification'
require 'pact_broker/verifications/latest_verifications_by_consumer_version'

module PactBroker
  module Verifications
    class Repository

      include PactBroker::Repositories::Helpers

      def create verification, pact
        verification.pact_version_id = pact_version_id_for(pact)
        verification.save
      end

      def verification_count_for_pact pact
        PactBroker::Domain::Verification.where(pact_version_id: pact_version_id_for(pact)).count
      end

      def find consumer_name, provider_name, pact_version_sha, verification_number
        PactBroker::Domain::Verification
          .join(:all_pact_publications, pact_version_id: :pact_version_id)
          .consumer(consumer_name)
          .provider(provider_name)
          .pact_version_sha(pact_version_sha)
          .verification_number(verification_number).first
      end

      def find_latest_verifications_for_consumer_version consumer_name, consumer_version_number
        # Use LatestPactPublicationsByConsumerVersion not AllPactPublcations because we don't
        # want verifications for shadowed revisions as it would be misleading.
        LatestVerificationsByConsumerVersion
          .join(:latest_pact_publications_by_consumer_versions, pact_version_id: :pact_version_id)
          .consumer(consumer_name)
          .consumer_version_number(consumer_version_number)
          .order(:provider_name)
      end

      def find_latest_verification_for consumer_name, provider_name
        query = LatestVerificationsByConsumerVersion
          .join(:all_pact_publications, pact_version_id: :pact_version_id)
          .consumer(consumer_name)
          .provider(provider_name)
          .latest
          query.first
      end

      def pact_version_id_for pact
        PactBroker::Pacts::PactPublication.select(:pact_version_id).where(id: pact.id)
      end
    end
  end
end
