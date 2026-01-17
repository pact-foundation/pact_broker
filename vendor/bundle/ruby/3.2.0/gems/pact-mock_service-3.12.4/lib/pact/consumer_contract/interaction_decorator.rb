require 'pact/shared/active_support_support'
require 'pact/consumer_contract/request_decorator'
require 'pact/consumer_contract/response_decorator'

module Pact
  class InteractionDecorator

    include ActiveSupportSupport

    def initialize interaction, decorator_options = {}
      @interaction = interaction
      @decorator_options = decorator_options
    end

    def as_json options = {}
      hash = { :description => interaction.description }
      hash[:providerState] = interaction.provider_state if interaction.provider_state
      hash[:request] = decorate_request.as_json(options)
      hash[:response] = decorate_response.as_json(options)
      fix_all_the_things hash
    end

    def to_json(options = {})
      as_json(options).to_json(options)
    end

    private

    attr_reader :interaction

    def decorate_request
      RequestDecorator.new(interaction.request, @decorator_options)
    end

    def decorate_response
      ResponseDecorator.new(interaction.response, @decorator_options)
    end

  end
end
