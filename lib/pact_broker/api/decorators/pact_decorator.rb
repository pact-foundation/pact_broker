require_relative 'base_decorator'

module PactBroker

  module Api

    module Decorators

      class PactDecorator < BaseDecorator

        property :createdAt, getter: lambda { |_|  created_at.xmlschema }
        property :updatedAt, getter: lambda { |_| updated_at.xmlschema }

        def to_hash(options = {})
          ::JSON.parse(represented.json_content).merge super
        end

        link :'pact-webhooks' do | options |
          {
            title: 'Webhooks for this pact',
            href: webhooks_for_pact_url(represented.consumer, represented.provider, options.fetch(:base_url))
          }
        end

      end
    end
  end
end