require 'roar/representer/json/hal'
require_relative 'pact_broker_urls'

module PactBroker
  module Api
    module Representors
      class VersionRepresenter < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::JSON::HAL::Links
        include PactBroker::Api::PactBrokerUrls

        property :number

        link :self do
          version_url(represented)
        end
      end
    end
  end
end