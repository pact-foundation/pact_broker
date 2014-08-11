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

        link :webhooks do | options |
          {
            title: 'POST to this resource to create a new webhook for this pact',
            href: webhooks_for_pact_url(represented, options.fetch(:base_url))
          }
        end

      end
    end
  end
end