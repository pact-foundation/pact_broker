require 'roar/decorator'
require 'roar/json/hal'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/api/decorators/decorator_context'
require 'pact_broker/api/decorators/format_date_time'

module PactBroker

  module Api

    module Decorators

      class BaseDecorator < Roar::Decorator
        include Roar::JSON::HAL
        include Roar::JSON::HAL::Links
        include PactBroker::Api::PactBrokerUrls
        include FormatDateTime
      end
    end
  end
end
