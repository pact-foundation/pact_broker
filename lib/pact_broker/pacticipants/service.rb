require "pact_broker/repositories"
require "pact_broker/logging"
require "pact_broker/messages"
require "pact_broker/pacticipants/find_potential_duplicate_pacticipant_names"

module PactBroker

  module Pacticipants
    class Service

      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging

      def self.messages_for_potential_duplicate_pacticipants(pacticipant_names, base_url)
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

      def self.find_pacticipant_by_name(name)
        pacticipant_repository.find_by_name(name)
      end

      def self.find_pacticipant_by_name!(name)
        pacticipant_repository.find_by_name!(name)
      end

      def self.find_by_id(id)
        pacticipant_repository.find_by_id(id)
      end

      def self.find(options)
        pacticipant_repository.find options
      end

      def self.find_all_pacticipant_versions_in_reverse_order(name, pagination_options = nil)
        pacticipant_repository.find_all_pacticipant_versions_in_reverse_order(name, pagination_options)
      end

      def self.find_pacticipant_repository_url_by_pacticipant_name(name)
        pacticipant = pacticipant_repository.find_by_name(name)
        if pacticipant && pacticipant.repository_url
          pacticipant.repository_url
        else
          nil
        end
      end

      def self.update(pacticipant_name, pacticipant)
        pacticipant_repository.update(pacticipant_name, pacticipant)
      end

      def self.create(params)
        pacticipant_repository.create(params)
      end

      def self.replace(pacticipant_name, open_struct_pacticipant)
        pacticipant_repository.replace(pacticipant_name, open_struct_pacticipant)
      end

      def self.delete(name)
        pacticipant = find_pacticipant_by_name name
        webhook_service.delete_all_webhhook_related_objects_by_pacticipant(pacticipant)
        pacticipant.destroy
      end

      def self.delete_if_orphan(pacticipant)
        pacticipant_repository.delete_if_orphan(pacticipant)
      end

      def self.pacticipant_names
        pacticipant_repository.pacticipant_names
      end
    end
  end
end
