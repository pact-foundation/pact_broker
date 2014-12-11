require 'roar/decorator'
require 'roar/json/hal'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/api/decorators/decorator_context'

module PactBroker

  module Api

    module Decorators

      class BaseDecorator < Roar::Decorator
        include Roar::JSON::HAL
        include Roar::JSON::HAL::Links
        include PactBroker::Api::PactBrokerUrls
      end
    end
  end
end
