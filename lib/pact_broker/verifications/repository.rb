require "pact_broker/domain/verification"
require "pact_broker/verifications/sequence"
require "pact_broker/verifications/latest_verification_id_for_pact_version_and_provider_version"
require "pact_broker/verifications/pact_version_provider_tag_successful_verification"
require "pact_broker/repositories/scopes"

module PactBroker
  module Verifications
    class Repository
      include PactBroker::Repositories
      include PactBroker::Repositories::Scopes

      # Ideally this would just be a sequence, but Sqlite and MySQL don't support sequences
      # in the way we need to use them ie. determining what the next number will be before we
      # create the record, because Webmachine wants to set the URL of the resource that is about
      # to be created *before* we actually create it.
      def next_number
        Sequence.next_val
      end

      def create verification, provider_version_number, pact_version
        version = version_repository.find_by_pacticipant_id_and_number_or_create(pact_version.provider_id, provider_version_number)
        verification.pact_version_id = pact_version.id
        verification.provider_version = version
        verification.provider_id = pact_version.provider_id
        verification.consumer_id = pact_version.consumer_id
        verification.tag_names = version.tag_names # TODO pass this in from contracts service
        verification.save
        update_latest_verification_id(verification)
        update_pact_version_provider_tag_verifications(verification, version.tag_names)
        verification
      end

      def delete(verification_id)
        scope_for(PactBroker::Domain::Verification).where(id: verification_id).delete
      end

      def update_latest_verification_id verification
        params = {
          pact_version_id: verification.pact_version_id,
          provider_version_id: verification.provider_version_id,
          provider_id: verification.provider_version.pacticipant_id,
          verification_id: verification.id,
          consumer_id: verification.consumer_id,
          created_at: verification.created_at
        }
        LatestVerificationIdForPactVersionAndProviderVersion.new(params).upsert
      end

      def update_pact_version_provider_tag_verifications(verification, tag_names)
        if verification.success
          tag_names&.each do | tag_name |
            PactVersionProviderTagSuccessfulVerification.new(
              pact_version_id: verification.pact_version_id,
              provider_version_tag_name: tag_name,
              wip: verification.wip,
              verification_id: verification.id,
              execution_date: verification.execution_date
            ).insert_ignore
          end
        end
      end

      # policy should be applied in resource
      def find consumer_name, provider_name, pact_version_sha, verification_number
        unscoped(PactBroker::Domain::Verification)
          .select_all_qualified
          .join(:all_pact_publications, pact_version_id: :pact_version_id)
          .consumer(consumer_name)
          .provider(provider_name)
          .pact_version_sha(pact_version_sha)
          .verification_number(verification_number).single_record
      end

      def find_latest_for_pact(pact)
        scope_for(PactBroker::Pacts::PactPublication).where(id: pact.id).single_record.latest_verification
      end

      def find_latest_from_main_branch_for_pact(pact)
        scope_for(PactBroker::Pacts::PactPublication).where(id: pact.id).single_record.latest_main_branch_verification
      end

      def any_verifications?(consumer, provider)
        scope_for(PactBroker::Domain::Verification).where(consumer_id: consumer.id, provider_id: provider.id).any?
      end

      def search_for_latest consumer_name, provider_name
        query = scope_for(PactBroker::Domain::Verification).select_all_qualified
        query = query.for_consumer_name(consumer_name) if consumer_name
        query = query.for_provider_name(provider_name) if provider_name
        query.reverse(:execution_date, :id).first
      end

      def find_latest_verifications_for_consumer_version consumer_name, consumer_version_number
        # Use remove_verifications_for_overridden_consumer_versions because we don't
        # want verifications for shadowed revisions as it would be misleading.
        scope_for(PactBroker::Domain::Verification)
          .select_all_qualified
          .remove_verifications_for_overridden_consumer_versions
          .for_consumer_name_and_consumer_version_number(consumer_name, consumer_version_number)
          .latest_by_pact_version
          .eager(:provider)
          .all
          .sort_by { | v | v.provider_name.downcase }
      end

      # The most recent verification for the latest revision of the pact
      # belonging to the version with the largest consumer_version_order.

      def find_latest_verification_for consumer_name, provider_name, consumer_version_tag = nil
        consumer = pacticipant_repository.find_by_name!(consumer_name)
        provider = pacticipant_repository.find_by_name!(provider_name)
        join_cols = {
          Sequel[:lp][:pact_version_id] => Sequel[:verifications][:pact_version_id],
          Sequel[:lp][:consumer_id] => consumer.id,
          Sequel[:lp][:provider_id] => provider.id
        }
        query = scope_for(PactBroker::Domain::Verification)
          .select_all_qualified
          .join(:latest_verification_ids_for_pact_versions, { Sequel[:verifications][:id] => Sequel[:lv][:latest_verification_id] }, { table_alias: :lv })
          .join(:latest_pact_publication_ids_for_consumer_versions, join_cols, { table_alias: :lp })
          .join(:versions, { Sequel[:cv][:id] => Sequel[:lp][:consumer_version_id] }, { table_alias: :cv })
        if consumer_version_tag == :untagged
          query = query.left_outer_join(:tags, { Sequel[:cv][:id] => Sequel[:tags][:version_id] })
                        .where(Sequel[:tags][:name] => nil)
        elsif consumer_version_tag
          query = query.join(:tags, { Sequel[:cv][:id] => Sequel[:tags][:version_id], Sequel[:tags][:name] => consumer_version_tag })
        end
        query.reverse_order(
          Sequel[:cv][:order],
          Sequel[:verifications][:number]
        ).limit(1).single_record
      end

      def find_latest_verification_for_tags consumer_name, provider_name, consumer_version_tag, provider_version_tag
        view_name = PactBroker::Domain::Verification.table_name
        consumer = pacticipant_repository.find_by_name!(consumer_name)
        provider = pacticipant_repository.find_by_name!(provider_name)

        consumer_tag_filter = Sequel.name_like(Sequel.qualify(:consumer_tags, :name), consumer_version_tag)
        provider_tag_filter = Sequel.name_like(Sequel.qualify(:provider_tags, :name), provider_version_tag)

        query = scope_for(PactBroker::Domain::Verification)
          .select_all_qualified
          .join(:versions, { Sequel[:provider_versions][:id] => Sequel[view_name][:provider_version_id] }, { table_alias: :provider_versions })
          .join(:latest_verification_id_for_pact_version_and_provider_version, { Sequel[:lv][:verification_id] => Sequel[view_name][:id] }, { table_alias: :lv })
          .join(:latest_pact_publication_ids_for_consumer_versions, { Sequel[view_name][:pact_version_id] => Sequel[:lp][:pact_version_id] }, { table_alias: :lp })
          .join(:versions, { Sequel[:consumer_versions][:id] => Sequel[:lp][:consumer_version_id] }, { table_alias: :consumer_versions })
          .join(:tags, { Sequel[:consumer_tags][:version_id] => Sequel[:lp][:consumer_version_id]}, { table_alias: :consumer_tags })
          .join(:tags, { Sequel[:provider_tags][:version_id] => Sequel[view_name][:provider_version_id]}, { table_alias: :provider_tags })
          .where(consumer: consumer, provider: provider)
          .where(consumer_tag_filter)
          .where(provider_tag_filter)

        query.reverse_order(
          Sequel[:consumer_versions][:order],
          Sequel[:provider_versions][:order],
          Sequel[view_name][:execution_date]
        ).limit(1).single_record
      end

      def delete_by_provider_version_id version_id
        scope_for(PactBroker::Domain::Verification).where(provider_version_id: version_id).delete
      end

      def delete_all_verifications_between(consumer_name, options)
        consumer = pacticipant_repository.find_by_name!(consumer_name)
        provider = pacticipant_repository.find_by_name!(options.fetch(:and))
        scope_for(PactBroker::Domain::Verification).where(provider: provider, consumer: consumer).delete
      end
    end
  end
end
