require 'pact_broker/repositories'

module PactBroker

  module Services
    module TagService

      extend self

      extend PactBroker::Repositories

      def create args
        pacticipant = pacticipant_repository.find_by_name_or_create args.fetch(:pacticipant_name)
        version = version_repository.find_by_pacticipant_id_and_number_or_create pacticipant.id, args.fetch(:pacticipant_version_number)
        tag_repository.create version: version, name: args.fetch(:tag_name)
      end

      def find args
        tag_repository.find args
      end

    end
  end

end