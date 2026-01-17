require 'pact/shared/active_support_support'
require 'pact/mock_service/request_decorator'
require 'pact/mock_service/response_decorator'

# Represents the Interaction in the form required by the MockService
# The json generated will be posted to the MockService to register the expectation

module Pact
  module MockService
    class InteractionDecorator

      include ActiveSupportSupport

      def initialize interaction
        @interaction = interaction
      end

      def as_json options = {}
        fix_all_the_things to_hash
      end

      def to_json(options = {})
        as_json.to_json(options)
      end

      def to_hash
        hash = { :description => interaction.description }
        hash[:providerState] = interaction.provider_state if interaction.provider_state
        hash[:request] = decorate_request.as_json
        hash[:response] = decorate_response.as_json
        hash[:metadata] = interaction.metadata
        hash
      end

      private

      attr_reader :interaction

      def decorate_request
        RequestDecorator.new(interaction.request)
      end

      def decorate_response
        ResponseDecorator.new(interaction.response)
      end

    end
  end
end
