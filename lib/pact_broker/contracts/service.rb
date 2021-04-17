require 'pact_broker/logging'
require 'pact_broker/repositories'
require 'pact_broker/services'
require 'base64'

module PactBroker
  module Contracts
    module Service
      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging

      def self.publish(parsed_contracts, webhook_options)
        version_params = {
          build_url: parsed_contracts.build_url,
          tags: parsed_contracts.tags&.collect{ | name| OpenStruct.new(name: name) },
          branch: parsed_contracts.branch
        }.compact
        version = version_service.create_or_update(
          parsed_contracts.pacticipant_name,
          parsed_contracts.version_number,
          OpenStruct.new(version_params)
        )

        pacts = parsed_contracts.contracts.collect do | contract |
          decoded_content = Base64.strict_decode64(contract.content)
          pact_params = PactBroker::Pacts::PactParams.new(
            consumer_name: parsed_contracts.pacticipant_name,
            provider_name: contract.provider_name,
            consumer_version_number: parsed_contracts.version_number,
            json_content: decoded_content
          )
          pact_service.create_or_update_pact(pact_params, webhook_options)
        end

        log = OpenStruct.new(level: "info", message: "Pact published")
        OpenStruct.new(
          pacticipant: version.pacticipant,
          version: version,
          contracts: pacts,
          logs: [log]
        )
      end
    end
  end
end
