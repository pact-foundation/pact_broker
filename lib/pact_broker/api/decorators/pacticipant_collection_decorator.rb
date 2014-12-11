require 'roar/json/hal'
require 'pact_broker/api/pact_broker_urls'
require_relative 'embedded_version_decorator'

module PactBroker

  module Api

    module Decorators

      class PacticipantCollectionRepresenter < BaseDecorator

        collection :pacticipants, exec_context: :decorator, :class => PactBroker::Domain::Pacticipant, :extend => PactBroker::Api::Decorators::PacticipantRepresenter

        def pacticipants
          represented
        end

        link :self do | options |
          pacticipants_url options[:base_url]
        end

        links :pacticipants do | options |
          represented.collect{ | pacticipant | {:href => pacticipant_url(options[:base_url], pacticipant), :title => pacticipant.name } }
        end

      end
    end
  end
end
