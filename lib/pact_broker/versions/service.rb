require 'pact_broker/repositories'

module PactBroker
  module Versions
    class Service

      extend PactBroker::Repositories

      def self.find_latest_by_pacticpant_name params
        version_repository.find_latest_by_pacticpant_name params.fetch(:pacticipant_name)
      end

      def self.find_by_pacticipant_name_and_number params
        version_repository.find_by_pacticipant_name_and_number params.fetch(:pacticipant_name), params.fetch(:pacticipant_version_number)
      end

      def self.find_by_pacticipant_name_and_latest_tag(pacticipant_name, tag)
        version_repository.find_by_pacticipant_name_and_latest_tag(pacticipant_name, tag)
      end

      def self.create_or_overwrite(pacticipant_name, version_number, version)
        pacticipant = pacticipant_repository.find_by_name_or_create(pacticipant_name)
        version_repository.create_or_overwrite(pacticipant, version_number, version)
      end

      def self.delete version
        tag_repository.delete_by_version_id version.id
        webhook_repository.delete_triggered_webhooks_by_version_id version.id
        pact_repository.delete_by_version_id version.id
        verification_repository.delete_by_provider_version_id version.id
        version_repository.delete_by_id version.id
      end
    end
  end
end
