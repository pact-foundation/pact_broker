require 'sequel'
require 'pact_broker/domain/version'
require 'pact_broker/tags/repository'

module PactBroker
  module Versions
    class Repository

      include PactBroker::Repositories::Helpers

      def find_by_pacticipant_id_and_number pacticipant_id, number
        PactBroker::Domain::Version.where(number: number, pacticipant_id: pacticipant_id).single_record
      end

      def find_by_pacticipant_name_and_number pacticipant_name, number
        PactBroker::Domain::Version
          .select(Sequel[:versions][:id], Sequel[:versions][:number], Sequel[:versions][:pacticipant_id], Sequel[:versions][:order], Sequel[:versions][:created_at], Sequel[:versions][:updated_at])
          .join(:pacticipants, {id: :pacticipant_id})
          .where(name_like(:number, number))
          .where(name_like(:name, pacticipant_name))
          .single_record
      end

      def create args
        PactBroker.logger.info "Creating version #{args[:number]} for pacticipant_id=#{args[:pacticipant_id]}"
        version = PactBroker::Domain::Version.new(number: args[:number], pacticipant_id: args[:pacticipant_id]).save
        PactBroker::Domain::Version.find(id: version.id) # Need to reload with populated order
      end

      def find_by_pacticipant_id_and_number_or_create pacticipant_id, number
        if version = find_by_pacticipant_id_and_number(pacticipant_id, number)
          version
        else
          create(pacticipant_id: pacticipant_id, number: number)
        end
      end

      def delete_by_id version_ids
        Sequel::Model.db[:versions].where(id: version_ids).delete
      end
    end
  end
end
