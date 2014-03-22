require 'sequel'
require 'pact_broker/models/version'

module PactBroker
  module Repositories
    class VersionRepository

      def find_by_pacticipant_id_and_number pacticipant_id, number
        PactBroker::Models::Version.where(number: number, pacticipant_id: pacticipant_id).single_record
      end

      def find_by_pacticipant_name_and_number pacticipant_name, number
        PactBroker::Models::Version
          .where(number: number)
          .join(:pacticipants, {id: :pacticipant_id})
          .where(name: pacticipant_name)
          .single_record
      end

      def create args
        PactBroker.logger.info "Creating version #{args[:number]} for pacticipant_id=#{args[:pacticipant_id]}"
        PactBroker::Models::Version.new(number: args[:number], pacticipant_id: args[:pacticipant_id]).save
      end

      def find_by_pacticipant_id_and_number_or_create pacticipant_id, number
        if version = find_by_pacticipant_id_and_number(pacticipant_id, number)
          version
        else
          create(pacticipant_id: pacticipant_id, number: number)
        end
      end

    end
  end
end