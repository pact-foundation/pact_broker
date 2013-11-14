require 'roar/decorator'
require 'roar/representer/json/hal'
require 'pact_broker/api/decorators/pact_broker_urls'

module PactBroker

  module Api

    module Decorators

      class BaseDecorator < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::JSON::HAL::Links
        include PactBroker::Api::PactBrokerUrls

        def initialize represented, base_url = nil
          super(represented)
          @base_url = base_url
        end

        def to_json
          json = super()
          if @base_url
            json.gsub(base_url_placeholder, @base_url)
          else
            json
          end
        end

      end
    end
  end
end