require_relative 'base_decorator'
require_relative 'version_decorator'
require_relative 'pact_decorator'
require_relative 'representable_pact'

module PactBroker

  module Api

    module Decorators

      class PactCollectionRepresenter < BaseDecorator
        include Roar::Representer::JSON::HAL
        include PactBroker::Api::PactBrokerUrls

        collection :pacts, decorator_scope: true, :class => PactBroker::Models::Pact, :extend => PactBroker::Api::Decorators::PactRepresenter

        def pacts
          represented.collect{ | pact | create_representable_pact(pact) }
        end

        def create_representable_pact pact
          PactBroker::Api::Decorators::RepresentablePact.new(pact)
        end

        link :self do
          latest_pacts_url
        end

        # This is the LATEST pact URL
        links :pacts do
          represented.collect{ | pact | {:href => latest_pact_url(pact), :consumer => pact.consumer.name, :provider => pact.provider.name } }
        end

      end
    end
  end
end