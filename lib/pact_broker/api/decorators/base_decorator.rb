require 'roar/decorator'
require 'roar/representer/json/hal'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/api/decorators/decorator_context'

module PactBroker

  module Api

    module Decorators

      class BaseDecorator < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::JSON::HAL::Links
        include PactBroker::Api::PactBrokerUrls
      end
    end
  end
end
