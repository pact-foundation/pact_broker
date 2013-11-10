require 'roar/representer/json/hal'
require_relative 'pact_broker_urls'
require_relative 'version_representor'

module PactBroker

  module Api

    module Representors

      module PacticipantCollectionRepresenter
        include Roar::Representer::JSON::HAL
        include PactBroker::Api::PactBrokerUrls


        collection :pacticipants, :class => PactBroker::Models::Pacticipant, :extend => PactBroker::Api::Representors::PacticipantRepresenter

        def pacticipants
          self
        end

        link :self do
          pacticipants_url
        end

        links :pacticipants do
          collect{ | pacticipant | {:href => pacticipant_url(pacticipant), :name => pacticipant.name } }
        end

      end
    end
  end
end