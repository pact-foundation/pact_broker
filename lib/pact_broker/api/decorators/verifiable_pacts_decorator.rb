require_relative "base_decorator"
require_relative "verifiable_pact_decorator"
require "pact_broker/api/pact_broker_urls"

module PactBroker
  module Api
    module Decorators
      class VerifiablePactsDecorator < BaseDecorator
        collection :entries, as: :pacts, embedded: true, :extend => PactBroker::Api::Decorators::VerifiablePactDecorator

        link :self do | context |
          {
            href: context[:resource_url],
            title: "Pacts to be verified"
          }
        end
      end
    end
  end
end
