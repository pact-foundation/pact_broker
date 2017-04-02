require 'pact_broker/repositories'

module PactBroker

  module Versions
    class Service

      extend PactBroker::Repositories

      def self.find_by_pacticipant_name_and_number params
        version_repository.find_by_pacticipant_name_and_number params.fetch(:pacticipant_name), params.fetch(:pacticipant_version_number)
      end
    end
  end
end