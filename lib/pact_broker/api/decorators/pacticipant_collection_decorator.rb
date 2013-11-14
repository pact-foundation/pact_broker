require 'roar/representer/json/hal'
require_relative 'pact_broker_urls'
require_relative 'version_decorator'

module Roar
  module Representer
    module Feature

      module Hypermedia

        #Monkey patch alert! Get "no method rel for Nil" when there is an empty array
        #in links. Cannot reproduce this in the roar tests :(
        alias_method :original_compile_links_for, :compile_links_for

        def compile_links_for configs, *args
          original_compile_links_for(configs, *args).select(&:any?)
        end

      end
    end
  end
end


module PactBroker

  module Api

    module Decorators

      class PacticipantCollectionRepresenter < BaseDecorator

        collection :pacticipants, decorator_scope: true, :class => PactBroker::Models::Pacticipant, :extend => PactBroker::Api::Decorators::PacticipantRepresenter

        def pacticipants
          represented
        end

        link :self do
          pacticipants_url
        end

        links :pacticipants do
          represented.collect{ | pacticipant | {:href => pacticipant_url(pacticipant), :name => pacticipant.name } }
        end

      end
    end
  end
end