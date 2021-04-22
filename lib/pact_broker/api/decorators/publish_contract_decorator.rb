require 'pact_broker/api/decorators/base_decorator'
require 'pact_broker/api/decorators/timestamps'

module PactBroker
  module Api
    module Decorators
      class PublishContractDecorator < BaseDecorator
        camelize_property_names

        property :consumer_name
        property :provider_name
        property :specification
        property :content_type
        property :decoded_content
      end
    end
  end
end
