require "pact_broker/services"

module PactBroker
  module Integrations
    class EventListener
      include PactBroker::Services

      # @param [Hash] params the params from the broadcast event
      # @option params [PactBroker::Domain::Pact] :pact the newly published pact
      def contract_published(params)
        integration_service.handle_contract_data_published(params.fetch(:pact).consumer, params.fetch(:pact).provider)
      end

      # @param [Hash] params the params from the broadcast event
      # @option params [PactBroker::Domain::Verification] :verification the newly published verification
      def provider_verification_published(params)
        integration_service.handle_contract_data_published(params.fetch(:verification).consumer, params.fetch(:verification).provider)
      end
    end
  end
end
