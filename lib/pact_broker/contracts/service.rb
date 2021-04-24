require 'pact_broker/logging'
require 'pact_broker/repositories'
require 'pact_broker/services'
require 'pact_broker/messages'

module PactBroker
  module Contracts

    LogMessage = Struct.new(:level, :message) do
      def self.info(message)
        LogMessage.new("info", message)
      end

      def self.warn(message)
        LogMessage.new("warn", message)
      end
    end

    module Service
      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging
      extend PactBroker::Messages

      def self.publish(parsed_contracts, webhook_options)
        version, version_logs = create_version(parsed_contracts)
        tags = create_tags(parsed_contracts, version)
        pacts, pact_logs = create_pacts(parsed_contracts, webhook_options)
        logs = version_logs + pact_logs
        OpenStruct.new(
          pacticipant: version.pacticipant,
          version: version,
          tags: tags,
          contracts: pacts,
          logs: logs
        )
      end

      # private

      def self.create_version(parsed_contracts)
        version_params = {
          build_url: parsed_contracts.build_url,
          branch: parsed_contracts.branch
        }.compact

        existing_version = find_existing_version(parsed_contracts)
        version = create_or_update_version(parsed_contracts, version_params)

        message = log_message_for_version_creation(existing_version, parsed_contracts)

        logs = [LogMessage.info(message)]
        return version, logs
      end

      def self.find_existing_version(parsed_contracts)
        version_service.find_by_pacticipant_name_and_number(
          pacticipant_name: parsed_contracts.pacticipant_name,
          pacticipant_version_number: parsed_contracts.version_number
        )
      end

      def self.create_or_update_version(parsed_contracts, version_params)
        version_service.create_or_update(
          parsed_contracts.pacticipant_name,
          parsed_contracts.version_number,
          OpenStruct.new(version_params)
        )
      end

      def self.create_tags(parsed_contracts, version)
        (parsed_contracts.tags || []).collect do | tag_name |
          tag_repository.create(version: version, name: tag_name)
        end
      end

      def self.create_pacts(parsed_contracts, webhook_options)
        logs = []
        pacts = parsed_contracts.contracts.select(&:pact?).collect do | contract_to_publish |
          pact_params = create_pact_params(parsed_contracts, contract_to_publish)
          existing_pact = pact_service.find_pact(pact_params)
          created_pact = create_or_merge_pact(contract_to_publish.merge?, existing_pact, pact_params, webhook_options)
          logs << log_mesage_for_pact_publication(parsed_contracts, contract_to_publish.merge?, existing_pact, created_pact)
          created_pact
        end
        return pacts, logs
      end

      def self.create_pact_params(parsed_contracts, contract_to_publish)
        PactBroker::Pacts::PactParams.new(
          consumer_name: parsed_contracts.pacticipant_name,
          provider_name: contract_to_publish.provider_name,
          consumer_version_number: parsed_contracts.version_number,
          json_content: contract_to_publish.decoded_content
        )
      end

      def self.create_or_merge_pact(merge, existing_pact, pact_params, webhook_options)
        if merge && existing_pact
          pact_service.merge_pact(pact_params, webhook_options)
        else
          pact_service.create_or_update_pact(pact_params, webhook_options)
        end
      end

      def self.log_message_for_version_creation(existing_version, parsed_contracts)
        message_params = parsed_contracts.to_h
        if parsed_contracts.tags&.any?
          message_params[:tags] = parsed_contracts.tags.join(", ")
        end
        message_params[:action] = existing_version ? "Updated" : "Created"
        LogMessage.info(message(log_message_key_for_version_creation(parsed_contracts), message_params))
      end

      def self.log_message_key_for_version_creation(parsed_contracts)
        if parsed_contracts.branch && parsed_contracts.tags&.any?
          "messages.version.created_for_branch_with_tags"
        elsif parsed_contracts.branch
          "messages.version.created_for_branch"
        elsif parsed_contracts.tags&.any?
          "messages.version.created_with_tags"
        else
          "messages.version.created"
        end
      end

      def self.log_mesage_for_pact_publication(parsed_contracts, merge, existing_pact, created_pact)
        log_message_params = {
          consumer_name: parsed_contracts.pacticipant_name,
          consumer_version_number: parsed_contracts.version_number
        }
        if merge
          if existing_pact
            LogMessage.info(message("messages.contract.pact_merged", log_message_params))
          else
            LogMessage.info(message("messages.contract.pact_published", log_message_params))
          end
        else
          if existing_pact
            if existing_pact.pact_version_sha != created_pact.pact_version_sha
              LogMessage.warn(message("messages.contract.pact_modified_for_same_version", log_message_params))
            else
              LogMessage.info(message("messages.contract.same_pact_content_published", log_message_params))
            end
          else
            LogMessage.info(message("messages.contract.pact_published", log_message_params))
          end
        end
      end
    end
  end
end
