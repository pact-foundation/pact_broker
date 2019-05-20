require_relative 'base_decorator'
require 'pact_broker/api/pact_broker_urls'

module PactBroker
  module Api
    module Decorators
      class VerifiablePactDecorator < BaseDecorator

        property :pending

        link :self do | context |
          {
            href: pact_version_url(represented, context[:base_url]),
            name: represented.name
          }
        end
      end
    end
  end
end
