require "pact_broker/api/decorators/base_decorator"

module PactBroker
  module Api
    module Decorators
      class ProviderStateDecorator < BaseDecorator
        camelize_property_names

        property :name
        property :params

      end

      class ProviderStatesDecorator < BaseDecorator
        collection :providerStates, getter: -> (context) { context[:represented].sort_by(&:name) }, :extend => PactBroker::Api::Decorators::ProviderStateDecorator
      end
    end
  end
end
