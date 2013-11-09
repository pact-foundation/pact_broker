require 'roar/representer/json/hal'
require_relative 'pact_broker_urls'
require_relative 'version_representor'

module PactBroker

  module Api

    module Representors

      module PactRepresenter
        include Roar::Representer::JSON::HAL
        include Roar::Representer::JSON::HAL::Links
        include PactBroker::Api::PactBrokerUrls


        property :consumer, :class => PactBroker::Models::Pacticipant, :extend => PactBroker::Api::Representors::PacticipantRepresenter, :embedded => true


        def consumer
          consumer_version.pacticipant
        end

        link :self do
          pact_url(self)
        end

      end
    end
  end
end