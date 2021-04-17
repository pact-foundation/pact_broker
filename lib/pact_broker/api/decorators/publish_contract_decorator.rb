require 'pact_broker/api/decorators/base_decorator'
require 'pact_broker/api/decorators/timestamps'

module PactBroker
  module Api
    module Decorators
      class PublishContractDecorator < BaseDecorator
        camelize_property_names

        property :role
        property :provider_name
        property :contract_specification
        property :content_type
        property :content
      end
    end
  end
end
