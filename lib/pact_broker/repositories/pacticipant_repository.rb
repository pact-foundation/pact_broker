require 'sequel'
require 'pact_broker/domain/pacticipant'

module PactBroker
  module Repositories
    class PacticipantRepository

      def find_by_name name
        PactBroker::Domain::Pacticipant.where(name: name).single_record
      end

      def find_by_id id
        PactBroker::Domain::Pacticipant.where(id: id).single_record
      end

      def find_all
        PactBroker::Domain::Pacticipant.order(:name).all
      end

      def find_by_name_or_create name
        if pacticipant = find_by_name(name)
          pacticipant
        else
          create name: name
        end
      end

      def create args
        PactBroker::Domain::Pacticipant.new(name: args[:name], repository_url: args[:repository_url]).save(raise_on_save_failure: true)
      end

      def pacticipant_names
        PactBroker::Domain::Pacticipant.select(:name).order(:name).collect{ | pacticipant| pacticipant.name }
      end

      def find_latest_version name

      end

    end
  end
end
