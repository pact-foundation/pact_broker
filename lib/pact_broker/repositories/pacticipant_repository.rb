require 'sequel'
require 'pact_broker/models/pacticipant'

module PactBroker
  module Repositories
    class PacticipantRepository

      def find_by_name name
        PactBroker::Models::Pacticipant.where(name: name).single_record
      end

      def find_by_id id
        PactBroker::Models::Pacticipant.where(id: id).single_record
      end

      def find_all
        PactBroker::Models::Pacticipant.order(:name).all
      end

      def find_by_name_or_create name
        if pacticipant = find_by_name(name)
          pacticipant
        else
          create name: name
        end
      end

      def create args
        PactBroker::Models::Pacticipant.new(name: args[:name], repository_url: args[:repository_url]).save(raise_on_save_failure: true)
      end

      def pacticipant_names
        PactBroker::Models::Pacticipant.select(:name).order(:name).collect{ | pacticipant| pacticipant.name }
      end

      def find_latest_version name

      end

    end
  end
end
