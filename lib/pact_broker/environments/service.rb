require 'pact_broker/repositories'

module PactBroker
  module Environments
    module Service

      extend self

      extend PactBroker::Repositories

      def create args
        pacticipant = pacticipant_repository.find_by_name_or_create args.fetch(:pacticipant_name)
        version = version_repository.find_by_pacticipant_id_and_number_or_create pacticipant.id, args.fetch(:pacticipant_version_number)
        environment_repository.create version: version, name: args.fetch(:environment_name)
      end

      def find args
        environment_repository.find args
      end

      def delete args
        version = version_repository.find_by_pacticipant_name_and_number args.fetch(:pacticipant_name), args.fetch(:pacticipant_version_number)
        Environment.where(name: args.fetch(:environment_name), version_id: version.id).delete
      end

      def find_all_environment_names_for_pacticipant pacticipant_name
        environment_repository.find_all_environment_names_for_pacticipant pacticipant_name
      end
    end
  end
end
