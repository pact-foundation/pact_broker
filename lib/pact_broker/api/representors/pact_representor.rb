require_relative 'base_decorator'
require_relative 'pact_pacticipant_representor'

module PactBroker

  module Api

    module Representors

      class PactRepresenter < BaseDecorator

        property :consumer, :extend => PactBroker::Api::Representors::PactPacticipantRepresenter, :embedded => true
        property :provider, :extend => PactBroker::Api::Representors::PactPacticipantRepresenter, :embedded => true

        link :self do
          pact_url(represented)
        end

      end
    end
  end
end