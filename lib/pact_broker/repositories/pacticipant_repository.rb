require 'sequel'
require 'pact_broker/models/pacticipant'

module PactBroker
  module Repositories
    class PacticipantRepository

      def find_by_name name
        PactBroker::Models::Pacticipant.where(name: name).first
      end

      def create args
        PactBroker::Models::Pacticipant.new(name: args[:name]).save
      end

    end
  end
end