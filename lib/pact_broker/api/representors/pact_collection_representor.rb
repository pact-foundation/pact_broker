require 'roar/representer/json/hal'
require_relative 'pact_broker_urls'
require_relative 'version_representor'
require_relative 'pact_representor'

module PactBroker

  module Api

    module Representors

      module PactCollectionRepresenter
        include Roar::Representer::JSON::HAL
        include PactBroker::Api::PactBrokerUrls


        collection :pacts, :class => PactBroker::Models::Pact, :extend => PactBroker::Api::Representors::PactRepresenter

        def pacts
          self
        end

        link :self do
          latest_pacts_url
        end

        links :pacts do
          collect{ | pact | {:href => pact_url(pact) } }
        end

      end
    end
  end
end