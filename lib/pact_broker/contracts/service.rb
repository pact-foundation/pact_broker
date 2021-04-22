require 'pact_broker/logging'
require 'pact_broker/repositories'
require 'pact_broker/services'

module PactBroker
  module Contracts
    module Service
      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging

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

        existing_version = version_service.find_by_pacticipant_name_and_number(
          pacticipant_name: parsed_contracts.pacticipant_name,
          pacticipant_version_number: parsed_contracts.version_number
        )

        version = version_service.create_or_update(
          parsed_contracts.pacticipant_name,
          parsed_contracts.version_number,
          OpenStruct.new(version_params)
        )

        message = log_message_for_pact_creation(existing_version, version_params, parsed_contracts)

        if message && parsed_contracts.branch
          message = message + " (branch #{parsed_contracts.branch})"
        end

        logs = [OpenStruct.new(level: "info", message: message)]
        return version, logs
      end

      def self.create_tags(parsed_contracts, version)
        (parsed_contracts.tags || []).collect do | tag_name |
          tag_repository.create(version: version, name: tag_name)
        end
      end

      def self.create_pacts(parsed_contracts, webhook_options)
        logs = []
        pacts = parsed_contracts.contracts.collect do | contract |
          pact_params = PactBroker::Pacts::PactParams.new(
            consumer_name: parsed_contracts.pacticipant_name,
            provider_name: contract.provider_name,
            consumer_version_number: parsed_contracts.version_number,
            json_content: contract.decoded_content
          )
          logs << OpenStruct.new(level: "info", message: "Pact published")
          pact_service.create_or_update_pact(pact_params, webhook_options)
        end
        return pacts, logs
      end

      def self.log_message_for_pact_creation(existing_version, version_params, parsed_contracts)
        if existing_version && version_params.any?
          "Updated version #{parsed_contracts.version_number} of #{parsed_contracts.pacticipant_name}"
        elsif !existing_version
          "Created version #{parsed_contracts.version_number} of #{parsed_contracts.pacticipant_name}"
        end
      end
    end
  end
end
