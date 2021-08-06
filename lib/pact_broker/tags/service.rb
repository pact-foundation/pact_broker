require "pact_broker/repositories"
require "pact_broker/configuration"
require "pact_broker/logging"

module PactBroker
  module Tags
    module Service
      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging

      def create args
        tag_name = args.fetch(:tag_name)
        pacticipant = pacticipant_repository.find_by_name_or_create args.fetch(:pacticipant_name)
        version = version_repository.find_by_pacticipant_id_and_number_or_create pacticipant.id, args.fetch(:pacticipant_version_number)
        version_service.maybe_set_version_branch_from_tag(version, tag_name)
        pacticipant_service.maybe_set_main_branch(version.pacticipant, tag_name)
        tag_repository.create(version: version, name: tag_name)
      end

      def find args
        tag_repository.find args
      end

      def delete args
        version = version_repository.find_by_pacticipant_name_and_number args.fetch(:pacticipant_name), args.fetch(:pacticipant_version_number)
        connection = PactBroker::Domain::Tag.new.db
        connection.run("delete from tags where name = '#{args.fetch(:tag_name)}' and version_id = '#{version.id}'")
      end

      def find_all_tag_names_for_pacticipant pacticipant_name
        tag_repository.find_all_tag_names_for_pacticipant pacticipant_name
      end
    end
  end
end
