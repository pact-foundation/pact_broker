require_relative 'pact_broker_urls'
require_relative 'version_representor'
require_relative 'base_decorator'


module PactBroker

  module Api

    module Representors

      class PactPacticipantRepresenter < BaseDecorator

        property :name
        property :repository_url
        property :version, :class => "PactBroker::Models::Version", :extend => PactBroker::Api::Representors::VersionRepresenter, :embedded => true

        link :self do
          pacticipant_url(represented)
        end

      end
    end
  end
end