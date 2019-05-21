require_relative 'base_decorator'
require_relative 'pact_pacticipant_decorator'

module PactBroker
  module Api
    module Decorators
      class PactDetailsDecorator < BaseDecorator
        property :consumer, :extend => PactBroker::Api::Decorators::PactPacticipantDecorator, :embedded => true
        property :provider, :extend => PactBroker::Api::Decorators::PactPacticipantDecorator, :embedded => true

        link :self do | options |
          pact_url(options[:base_url], represented)
        end
      end
    end
  end
end
