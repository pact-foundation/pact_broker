require 'pact_broker/repositories'

module PactBroker

  module Labels
    module Service

      extend self

      extend PactBroker::Repositories

      def create args
        pacticipant = pacticipant_repository.find_by_name_or_create args.fetch(:pacticipant_name)
        label_repository.create pacticipant: pacticipant, name: args.fetch(:label_name)
      end

      def find args
        label_repository.find args
      end

      def delete args
        label_repository.delete args
      end
    end
  end
end
