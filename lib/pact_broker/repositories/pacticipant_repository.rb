require 'sequel'
require 'pact_broker/models/pacticipant'

module PactBroker
  module Repositories
    class PacticipantRepository

      def find_by_name name
        PactBroker::Models::Pacticipant.where(name: name).single_record
      end

      def create args
        PactBroker::Models::Pacticipant.new(name: args[:name], repository_url: args[:repository_url]).save(raise_on_save_failure: true)
      end

    end
  end
end
