require 'roar/representer/json/hal'
require_relative 'pact_broker_urls'
require_relative 'version_representor'

module PactBroker

  module Api

    module Representors

      module PactPacticipantRepresenter
        include Roar::Representer::JSON::HAL
        include Roar::Representer::JSON::HAL::Links
        include PactBroker::Api::PactBrokerUrls

        property :name
        property :repository_url
        property :version, :class => "PactBroker::Models::Version", :extend => PactBroker::Api::Representors::VersionRepresenter, :embedded => true

        link :self do
          pacticipant_url(self)
        end

      end
    end
  end
end