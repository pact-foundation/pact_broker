require_relative 'base_decorator'
require 'pact_broker/json'

module PactBroker

  module Api

    module Decorators

      class PactDecorator < BaseDecorator

        property :createdAt, getter: lambda { |_|  created_at.xmlschema }, writeable: false
        property :updatedAt, getter: lambda { |_| updated_at.xmlschema }, writeable: false

        def to_hash(options = {})
          ::JSON.parse(represented.json_content, PACT_PARSING_OPTIONS).merge super
        end

        link :'latest-pact' do | options |
          {
            title: "Latest version of the pact between #{represented.consumer.name} and #{represented.provider.name}",
            href: latest_pact_url(options.fetch(:base_url), represented)

          }
        end

        link :'pact-webhooks' do | options |
          {
            title: "Webhooks for the pact between #{represented.consumer.name} and #{represented.provider.name}",
            href: webhooks_for_pact_url(represented.consumer, represented.provider, options.fetch(:base_url))
          }
        end

      end
    end
  end
end