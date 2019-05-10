require_relative 'base_decorator'
require_relative 'integration_decorator'

module PactBroker
  module Api
    module Decorators
      class IntegrationsDecorator < BaseDecorator
        collection :entries, as: :integrations, embedded: true, :extend => PactBroker::Api::Decorators::IntegrationDecorator

        link :self do | context |
          {
            href: context[:resource_url],
            title: "All integrations"
          }
        end
      end
    end
  end
end
