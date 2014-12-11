require 'roar/json/hal'
require 'pact_broker/api/pact_broker_urls'
require_relative 'embedded_version_decorator'

module PactBroker

  module Api

    module Decorators

      class PacticipantCollectionRepresenter < BaseDecorator

        collection :entries, :as => :pacticipants, :class => PactBroker::Domain::Pacticipant, :extend => PactBroker::Api::Decorators::PacticipantRepresenter

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
