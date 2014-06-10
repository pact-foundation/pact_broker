require 'pact_broker/repositories'
require 'pact_broker/models/relationship'

module PactBroker

  module Services
    class PacticipantService

      extend PactBroker::Repositories
      extend PactBroker::Repositories

      def self.find_all_pacticipants
        pacticipant_repository.find_all
      end

      def self.find_pacticipant_by_name name
        pacticipant_repository.find_by_name(name)
      end

      def self.find_pacticipant_repository_url_by_pacticipant_name name
        pacticipant = pacticipant_repository.find_by_name(name)
        if pacticipant && pacticipant.repository_url
          pacticipant.repository_url
        else
          nil
        end
      end

      def self.find_relationships
        pact_repository.find_latest_pacts.collect{ | pact| PactBroker::Models::Relationship.create pact.consumer, pact.provider }
      end

      def self.update params
        pacticipant = pacticipant_repository.find_by_name(params.fetch(:name))
        pacticipant.update(params)
        pacticipant_repository.find_by_name(params.fetch(:name))
      end

      def self.create params
        pacticipant_repository.create(params)
      end

      def self.delete name
        connection = PactBroker::Models::Pacticipant.new.db
        connection.run("delete from tags where version_id IN (select id from versions where pacticipant_id IN (select id from pacticipants where name = '#{name}'))")
        connection.run("delete from pacts where version_id IN (select id from versions where pacticipant_id IN (select id from pacticipants where name = '#{name}'))")
        connection.run("delete from pacts where provider_id IN (select id from pacticipants where name = '#{name}')")
        connection.run("delete from versions where pacticipant_id IN (select id from pacticipants where name = '#{name}')")
        connection.run("delete from pacticipants where name = '#{name}'")
      end

    end
  end
end