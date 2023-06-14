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
      extend PactBroker::Messages

      def self.messages_for_potential_duplicate_pacticipants(pacticipant_names, base_url)
        messages = []
        pacticipant_names.each do | name |
          potential_duplicate_pacticipants = find_potential_duplicate_pacticipants(name)
          if potential_duplicate_pacticipants.any?
            messages << potential_duplicate_pacticipant_message(name, potential_duplicate_pacticipants, base_url)
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

      def self.find_all_pacticipants(filter_options = {}, pagination_options = {}, eager_load_associations = [])
        pacticipant_repository.find_all(filter_options, pagination_options, eager_load_associations)
      end

      def self.find_pacticipant_by_name(name)
        pacticipant_repository.find_by_name(name)
      end

      # Used by pf
      # @param [Array<String>]
      # @return [Array<PactBroker::Domain::Pacticipant>]
      def self.find_pacticipants_by_names(names)
        pacticipant_repository.find_by_names(names)
      end

      def self.find_pacticipant_by_name!(name)
        pacticipant_repository.find_by_name!(name)
      end

      def self.find_by_id(id)
        pacticipant_repository.find_by_id(id)
      end

      def self.find(options, pagination_options = {})
        pacticipant_repository.find(options, pagination_options)
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
        pacticipant_repository.delete(pacticipant)
      end

      def self.delete_if_orphan(pacticipant)
        pacticipant_repository.delete_if_orphan(pacticipant)
      end

      def self.pacticipant_names
        pacticipant_repository.pacticipant_names
      end

      def self.maybe_set_main_branch(pacticipant, potential_main_branch)
        if pacticipant.main_branch.nil? && PactBroker.configuration.auto_detect_main_branch && PactBroker.configuration.main_branch_candidates.include?(potential_main_branch)
          logger.info "Setting #{pacticipant.name} main_branch to '#{potential_main_branch}' (because the #{pacticipant.name} main_branch was nil and auto_detect_main_branch=true)"
          pacticipant_repository.set_main_branch(pacticipant, potential_main_branch)
        else
          pacticipant
        end
      end

      private_class_method def self.potential_duplicate_pacticipant_message(new_name, potential_duplicate_pacticipants, base_url)
        existing_names = potential_duplicate_pacticipants.
          collect{ | p | "* #{p.name}"  }.join("\n")
        message("errors.duplicate_pacticipant",
          new_name: new_name,
          existing_names: existing_names,
          base_url: base_url)
      end
    end
  end
end
