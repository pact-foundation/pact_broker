require 'roar/representer/json/hal'
require_relative 'pact_broker_urls'
require_relative 'pact_pacticipant_representor'

module PactBroker

  module Api

    module Representors

      module PactRepresenter
        include Roar::Representer::JSON::HAL
        include Roar::Representer::JSON::HAL::Links
        include PactBroker::Api::PactBrokerUrls


        property :consumer, :extend => PactBroker::Api::Representors::PactPacticipantRepresenter, :embedded => true
        property :provider, :extend => PactBroker::Api::Representors::PactPacticipantRepresenter, :embedded => true

        link :self do
          pact_url(self)
        end

      end
    end
  end
end