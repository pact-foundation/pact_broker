require 'roar/representer/json/hal'
require 'roar/decorator'
require_relative 'pact_broker_urls'
require_relative 'version_representor'

module PactBroker

  module Api

    module Representors

      class PacticipantRepresenter < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::JSON::HAL::Links
        include PactBroker::Api::PactBrokerUrls

        property :name
        property :repository_url

        property :last_version, :class => PactBroker::Models::Version, :extend => PactBroker::Api::Representors::VersionRepresenter, :embedded => true

        link :self do
          pacticipant_url(represented)
        end

        link :last_version do
          last_version_url(represented)
        end

        link :versions do
          versions_url(represented)
        end

        def to_json(base_url)
          json = super()
          json.gsub('http://localhost:1234', base_url)
        end
      end
    end
  end
end