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

        # This is the LATEST pact URL
        links :pacts do
          collect{ | pact | {:href => latest_pact_url(pact), :consumer => pact.consumer.name, :provider => pact.provider.name } }
        end

      end
    end
  end
end