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

      def self.find options
        pacticipant_repository.find options
      end

      def self.find_all_pacticipant_versions_in_reverse_order name
        pacticipant_repository.find_all_pacticipant_versions_in_reverse_order(name)
      end

      def self.find_pacticipant_repository_url_by_pacticipant_name name
        pacticipant = pacticipant_repository.find_by_name(name)
        if pacticipant && pacticipant.repository_url
          pacticipant.repository_url
        else
          nil
        end
      end

      # This needs to move into a new service
      def self.find_relationships
        pact_repository.find_latest_pacts
          .collect do | pact|
            latest_relationship = build_latest_pact_relationship(pact)
            prod_relationship = build_relationship_for_tagged_pact(pact, 'prod')
            production_relationship = build_relationship_for_tagged_pact(pact, 'production')
            [latest_relationship, prod_relationship, production_relationship].compact
          end.flatten
      end

      def self.build_latest_pact_relationship pact
        latest_verification = verification_service.find_latest_verification_for(pact.consumer, pact.provider)
        webhooks = webhook_service.find_by_consumer_and_provider pact.consumer, pact.provider
        triggered_webhooks = webhook_service.find_latest_triggered_webhooks pact.consumer, pact.provider
        tag_names = pact.consumer_version_tag_names.select{ |name| name == 'prod' || name == 'production' }
        PactBroker::Domain::Relationship.create pact.consumer, pact.provider, pact, true, latest_verification, webhooks, triggered_webhooks, tag_names
      end

      def self.build_relationship_for_tagged_pact latest_pact, tag
        pact = pact_service.find_latest_pact consumer_name: latest_pact.consumer_name, provider_name: latest_pact.provider_name, tag: tag
        return nil unless pact
        return nil if pact.id == latest_pact.id
        verification = verification_repository.find_latest_verification_for pact.consumer_name, pact.provider_name, tag
        PactBroker::Domain::Relationship.create pact.consumer, pact.provider, pact, false, verification, [], [], [tag]
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
        version_ids = PactBroker::Domain::Version.where(pacticipant_id: pacticipant.id).select_for_subquery(:id) #stupid mysql doesn't allow subqueries
        select_pacticipant = "select id from pacticipants where name = '#{name}'"
        tag_repository.delete_by_version_id version_ids
        webhook_service.delete_all_webhhook_related_objects_by_pacticipant pacticipant
        pact_repository.delete_by_version_id version_ids
        connection.run("delete from pact_publications where provider_id = #{pacticipant.id}")
        connection.run("delete from verifications where pact_version_id IN (select id from pact_versions where provider_id = #{pacticipant.id})")
        connection.run("delete from verifications where pact_version_id IN (select id from pact_versions where consumer_id = #{pacticipant.id})")
        connection.run("delete from pact_versions where provider_id = #{pacticipant.id}")
        connection.run("delete from pact_versions where consumer_id = #{pacticipant.id}")
        connection.run("delete from versions where pacticipant_id = #{pacticipant.id}")
        version_repository.delete_by_id version_ids
        connection.run("delete from pacticipants where id = #{pacticipant.id}")
      end

      def self.pacticipant_names
        pacticipant_repository.pacticipant_names
      end

    end
  end
end