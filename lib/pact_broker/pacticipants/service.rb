require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'pact_broker/messages'
require 'pact_broker/domain/relationship'
require 'pact_broker/pacticipants/find_potential_duplicate_pacticipant_names'

module PactBroker

  module Pacticipants
    class Service

      extend PactBroker::Repositories
      extend PactBroker::Services
      extend PactBroker::Logging

      def self.messages_for_potential_duplicate_pacticipants pacticipant_names, base_url
        messages = []
        pacticipant_names.each do | name |
          potential_duplicate_pacticipants = find_potential_duplicate_pacticipants(name)
          if potential_duplicate_pacticipants.any?
            messages << Messages.potential_duplicate_pacticipant_message(name, potential_duplicate_pacticipants, base_url)
          end
        end
        messages
      end

      def self.find_potential_duplicate_pacticipants pacticipant_name
        PactBroker::Pacticipants::FindPotentialDuplicatePacticipantNames
          .call(pacticipant_name, pacticipant_names).tap { | names|
            if names.any?
              logger.info "The following potential duplicate pacticipants were found for #{pacticipant_name}: #{names.join(", ")}"
            end
          } .collect{ | name | pacticipant_repository.find_by_name(name) }
      end

      def self.find_all_pacticipants
        pacticipant_repository.find_all
      end

      def self.find_pacticipant_by_name name
        pacticipant_repository.find_by_name(name)
      end

      def self.find_all_pacticipant_versions name
        pacticipant_repository.find_all_pacticipant_versions(name)
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
        pact_repository.find_latest_pacts.collect{ | pact| PactBroker::Domain::Relationship.create pact.consumer, pact.provider }
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
        pacticipant = find_pacticipant_by_name name
        connection = PactBroker::Domain::Pacticipant.new.db
        connection.run("delete from tags where version_id IN (select id from versions where pacticipant_id IN (select id from pacticipants where name = '#{name}'))")
        connection.run("delete from pact_versions where consumer_version_id IN (select id from versions where pacticipant_id IN (select id from pacticipants where name = '#{name}'))")
        connection.run("delete from pact_versions where provider_id IN (select id from pacticipants where name = '#{name}')")
        # TODO delete orphan pact_version_contents
        connection.run("delete from versions where pacticipant_id IN (select id from pacticipants where name = '#{name}')")
        webhook_service.delete_by_pacticipant pacticipant
        connection.run("delete from pacticipants where name = '#{name}'")
      end

      def self.pacticipant_names
        pacticipant_repository.pacticipant_names
      end

    end
  end
end