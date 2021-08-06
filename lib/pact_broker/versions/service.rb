require "pact_broker/logging"
require "pact_broker/repositories"
require "pact_broker/messages"

module PactBroker
  module Versions
    class Service
      extend PactBroker::Messages
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging

      def self.conflict_errors(_existing_version, _open_struct_version, _version_url)
        # This validation is causing problems in the PF build when branches are merged
        # TODO remove this properly when re-doing the version -> branch relationship
        {}
        # if existing_version&.branch && open_struct_version.to_h.key?(:branch) && existing_version.branch != open_struct_version.branch
        #   message_params = {
        #     old_branch: existing_version&.branch,
        #     new_branch: open_struct_version.branch,
        #     version_url: version_url
        #   }
        #   error_message = message("errors.validation.cannot_modify_version_branch", message_params)
        #   { branch: [error_message] }
        # else
        #   {}
        # end
      end

      def self.find_latest_by_pacticpant_name params
        version_repository.find_latest_by_pacticpant_name params.fetch(:pacticipant_name)
      end

      def self.find_by_pacticipant_name_and_number params
        version_repository.find_by_pacticipant_name_and_number params.fetch(:pacticipant_name), params.fetch(:pacticipant_version_number)
      end

      def self.find_by_pacticipant_name_and_latest_tag(pacticipant_name, tag)
        version_repository.find_by_pacticipant_name_and_latest_tag(pacticipant_name, tag)
      end

      def self.create_or_overwrite(pacticipant_name, version_number, version)
        pacticipant = pacticipant_repository.find_by_name_or_create(pacticipant_name)
        version = version_repository.create_or_overwrite(pacticipant, version_number, version)
        pacticipant_service.maybe_set_main_branch(pacticipant, version.branch)
        version
      end

      def self.create_or_update(pacticipant_name, version_number, version)
        pacticipant = pacticipant_repository.find_by_name_or_create(pacticipant_name)
        version = version_repository.create_or_update(pacticipant, version_number, version)
        pacticipant_service.maybe_set_main_branch(pacticipant, version.branch)
        version
      end

      def self.find_latest_version_from_main_branch(pacticipant)
        version_repository.find_latest_version_from_main_branch(pacticipant)
      end

      def self.delete version
        tag_repository.delete_by_version_id version.id
        webhook_repository.delete_triggered_webhooks_by_version_id version.id
        pact_repository.delete_by_version_id version.id
        verification_repository.delete_by_provider_version_id version.id
        version_repository.delete_by_id version.id
      end

      def self.maybe_set_version_branch_from_tag(version, tag_name)
        if use_tag_as_branch?(version) && !version.branch
          logger.info "Setting #{version.pacticipant.name} version #{version.number} branch to '#{tag_name}' from first tag (because use_first_tag_as_branch=true)"
          version_repository.set_branch_if_unset(version, tag_name)
        end
      end

      def self.use_tag_as_branch?(version)
        version.tags.count == 0 &&
          PactBroker.configuration.use_first_tag_as_branch &&
          ((now - version.created_at.to_datetime) * 24 * 60 * 60) <= PactBroker.configuration.use_first_tag_as_branch_time_limit
      end
      private_class_method :use_tag_as_branch?

      def self.now
        Time.now.utc.to_datetime
      end
      private_class_method :now
    end
  end
end
