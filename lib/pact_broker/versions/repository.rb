require 'sequel'
require 'pact_broker/logging'
require 'pact_broker/domain/version'
require 'pact_broker/tags/repository'

module PactBroker
  module Versions
    class Repository

      include PactBroker::Logging
      include PactBroker::Repositories::Helpers

      def find_by_pacticipant_id_and_number pacticipant_id, number
        PactBroker::Domain::Version.where(number: number, pacticipant_id: pacticipant_id).single_record
      end

      def find_by_pacticipant_name_and_latest_tag pacticipant_name, tag
        PactBroker::Domain::Version
          .select_all_qualified
          .where_tag(tag)
          .where_pacticipant_name(pacticipant_name)
          .reverse_order(:order)
          .first
      end

      def find_by_pacticipant_name_and_tag pacticipant_name, tag
        PactBroker::Domain::Version
          .select_all_qualified
          .where_pacticipant_name(pacticipant_name)
          .where_tag(tag)
          .all
      end

      def find_latest_by_pacticpant_name pacticipant_name
        PactBroker::Domain::Version
          .select_all_qualified
          .where_pacticipant_name(pacticipant_name)
          .reverse_order(:order)
          .first
      end

      def find_by_pacticipant_name_and_number pacticipant_name, number
        PactBroker::Domain::Version
          .select_all_qualified
          .where_pacticipant_name(pacticipant_name)
          .where_number(number)
          .single_record
      end

      # There may be a race condition if two simultaneous requests come in to create the same version
      def create args
        logger.info "Upserting version #{args[:number]} for pacticipant_id=#{args[:pacticipant_id]}"
        version_params = {
          number: args[:number],
          pacticipant_id: args[:pacticipant_id],
          created_at: Sequel.datetime_class.now,
          updated_at: Sequel.datetime_class.now
        }

        PactBroker::Domain::Version.new(version_params).insert_ignore
      end

      def find_by_pacticipant_id_and_number_or_create pacticipant_id, number
        if version = find_by_pacticipant_id_and_number(pacticipant_id, number)
          version
        else
          create(pacticipant_id: pacticipant_id, number: number)
        end
      end

      def delete_by_id version_ids
        Domain::Version.where(id: version_ids).delete
      end

      def delete_orphan_versions consumer, provider
        version_ids_with_pact_publications = PactBroker::Pacts::PactPublication.where(consumer_id: [consumer.id, provider.id]).select(:consumer_version_id).collect{|r| r[:consumer_version_id]}
        version_ids_with_verifications = PactBroker::Domain::Verification.where(provider_id: [provider.id, consumer.id]).select(:provider_version_id).collect{|r| r[:provider_version_id]}
        # Hope we don't hit max parameter constraints here...
        version_ids_to_keep = (version_ids_with_pact_publications + version_ids_with_verifications).uniq

        PactBroker::Domain::Version
          .where(pacticipant_id: [consumer.id, provider.id])
          .exclude(id: (version_ids_with_pact_publications + version_ids_with_verifications).uniq)
          .delete
      end

      def find_versions_for_selector(selector)
        PactBroker::Domain::Version.select_all_qualified.for_selector(selector).all
      end
    end
  end
end
