require 'roar/decorator'
require 'roar/representer/json/hal'
require 'pact_broker/api/representors/pact_broker_urls'

module PactBroker

  module Api

    module Representors

      class BaseDecorator < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::JSON::HAL::Links
        include PactBroker::Api::PactBrokerUrls

        def to_json real_base_url
          json = super()
          json.gsub(base_url, real_base_url)
        end

      end
    end
  end
end