require 'sequel'
require 'pact_broker/models/version'

module PactBroker
  module Repositories
    class VersionRepository

      def find_by_pacticipant_name_and_number pacticipant_name, number
        Version.where(number: number).join(:pacticipants, :id => :pacticipant_id)
      end

      def create args
        PactBroker::Models::Version.new(number: args[:number], pacticipant_id: args[:pacticipant_id]).save
      end

    end
  end
end