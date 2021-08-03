require "sequel"
require "pact_broker/logging"
require "pact_broker/domain/version"
require "pact_broker/tags/repository"

module PactBroker
  module Versions
    class Repository

      include PactBroker::Logging
      include PactBroker::Repositories::Helpers
      include PactBroker::Repositories

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

        PactBroker::Domain::Version.new(version_params).upsert
      end

      def create_or_update(pacticipant, version_number, open_struct_version)
        saved_version = PactBroker::Domain::Version.where(pacticipant_id: pacticipant.id, number: version_number).single_record
        params = open_struct_version.to_h
        tags = params.delete(:tags)
        if saved_version
          saved_version.update(params)
        else
          # Upsert is only for race conditions
          # Upsert blanks out any fields that are not provided
          saved_version = PactBroker::Domain::Version.new(
            params.merge(
              pacticipant_id: pacticipant.id,
              number: version_number
            )
          ).upsert
        end

        replace_tags(saved_version, tags) if tags
        saved_version
      end

      def create_or_overwrite(pacticipant, version_number, open_struct_version)
        saved_version = PactBroker::Domain::Version.new(
          number: version_number,
          pacticipant: pacticipant,
          build_url: open_struct_version.build_url,
          branch: open_struct_version.branch
        ).upsert

        if open_struct_version.tags
          replace_tags(saved_version, open_struct_version.tags)
        end

        saved_version
      end

      def replace_tags(saved_version, open_struct_tags)
        tag_repository.delete_by_version_id(saved_version.id)
        open_struct_tags.collect do | open_struct_tag |
          tag_repository.create(version: saved_version, name: open_struct_tag.name)
        end
        saved_version.refresh
      end

      def find_by_pacticipant_id_and_number_or_create pacticipant_id, number
        version = find_by_pacticipant_id_and_number(pacticipant_id, number)

        version ? version : create(pacticipant_id: pacticipant_id, number: number)
      end

      def delete_by_id version_ids
        Domain::Version.where(id: version_ids).delete
      end

      def delete_orphan_versions consumer, provider
        version_ids_with_pact_publications = PactBroker::Pacts::PactPublication.where(consumer_id: [consumer.id, provider.id]).select(:consumer_version_id).collect{|r| r[:consumer_version_id]}
        version_ids_with_verifications = PactBroker::Domain::Verification.where(provider_id: [provider.id, consumer.id]).select(:provider_version_id).collect{|r| r[:provider_version_id]}
        # Hope we don't hit max parameter constraints here...
        PactBroker::Domain::Version
          .where(Sequel[:versions][:pacticipant_id] => [consumer.id, provider.id])
          .exclude(id: (version_ids_with_pact_publications + version_ids_with_verifications).uniq)
          .delete
      end

      def find_versions_for_selector(selector)
        PactBroker::Domain::Version.select_all_qualified.for_selector(selector).all
      end

      def set_branch_if_unset(version, branch)
        version.update(branch: branch) if version.branch.nil?
        version
      end
    end
  end
end
