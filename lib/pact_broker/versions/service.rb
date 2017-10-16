require 'pact_broker/repositories'

module PactBroker

  module Versions
    class Service

      extend PactBroker::Repositories

      def self.find_by_pacticipant_name_and_number params
        version_repository.find_by_pacticipant_name_and_number params.fetch(:pacticipant_name), params.fetch(:pacticipant_version_number)
      end

      def self.delete version
        tag_repository.delete_by_version_id version.id
        pact_repository.delete_by_version_id version.id
        version_repository.delete_by_id version.id
      end

      def self.find_versions_by_selector selectors
        selectors.collect do | selector |
          pacticipant_name, type, number = selector.split("/")
          version_repository.find_by_pacticipant_name_and_number pacticipant_name, number
        end
      end
    end
  end
end
