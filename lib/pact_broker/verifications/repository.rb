require 'sequel'
require 'pact_broker/domain/verification'
require 'pact_broker/verifications/latest_verifications_by_consumer_version'
require 'pact_broker/verifications/all_verifications'

module PactBroker
  module Verifications
    class Repository

      include PactBroker::Repositories::Helpers
      include PactBroker::Repositories

      def create verification, provider_version_number, pact
        provider = pacticipant_repository.find_by_name(pact.provider_name)
        version = version_repository.find_by_pacticipant_id_and_number_or_create(provider.id, provider_version_number)
        verification.pact_version_id = pact_version_id_for(pact)
        verification.provider_version = version
        verification.save
      end

      def verification_count_for_pact pact
        PactBroker::Domain::Verification.where(pact_version_id: pact_version_id_for(pact)).count
      end

      def find consumer_name, provider_name, pact_version_sha, verification_number
        PactBroker::Domain::Verification
          .select_all_qualified
          .join(:all_pact_publications, pact_version_id: :pact_version_id)
          .consumer(consumer_name)
          .provider(provider_name)
          .pact_version_sha(pact_version_sha)
          .verification_number(verification_number).single_record
      end

      def find_latest_verifications_for_consumer_version consumer_name, consumer_version_number
        # Use LatestPactPublicationsByConsumerVersion not AllPactPublcations because we don't
        # want verifications for shadowed revisions as it would be misleading.
        LatestVerificationsByConsumerVersion
          .select_all_qualified
          .join(:latest_pact_publications_by_consumer_versions, pact_version_id: :pact_version_id)
          .consumer(consumer_name)
          .consumer_version_number(consumer_version_number)
          .order(:provider_name)
          .all
      end

      # The most recent verification for the latest revision of the pact
      # belonging to the version with the largest consumer_version_order.

      def find_latest_verification_for consumer_name, provider_name, consumer_version_tag = nil
        query = LatestVerificationsByConsumerVersion
          .select_all_qualified
          .join(:all_pact_publications, pact_version_id: :pact_version_id)
          .consumer(consumer_name)
          .provider(provider_name)
        if consumer_version_tag == :untagged
          query = query.untagged
        elsif consumer_version_tag
          query = query.tag(consumer_version_tag)
        end
        query.reverse_order(
          Sequel[:all_pact_publications][:consumer_version_order],
          Sequel[:all_pact_publications][:revision_number],
          Sequel[LatestVerificationsByConsumerVersion.table_name][:number]
        ).limit(1).single_record
      end

      def find_latest_verification_for_tags consumer_name, provider_name, consumer_version_tag, provider_version_tag
        view_name = PactBroker::Verifications::AllVerifications.table_name
        query = PactBroker::Verifications::AllVerifications
          .select_all_qualified
          .join(:versions, {Sequel[:provider_versions][:id] => Sequel[view_name][:provider_version_id]}, {table_alias: :provider_versions})
          .join(:all_pact_publications, { Sequel[view_name][:pact_version_id] => Sequel[:all_pact_publications][:pact_version_id] })
          .consumer(consumer_name)
          .provider(provider_name)
          .tag(consumer_version_tag)
          .provider_version_tag(provider_version_tag)

        query.reverse_order(
          Sequel[:all_pact_publications][:consumer_version_order],
          Sequel[:all_pact_publications][:revision_number],
          Sequel[:provider_versions][:order],
          Sequel[view_name][:execution_date]
        ).limit(1).single_record
      end

      def pact_version_id_for pact
        PactBroker::Pacts::PactPublication.select(:pact_version_id).where(id: pact.id)
      end
    end
  end
end
