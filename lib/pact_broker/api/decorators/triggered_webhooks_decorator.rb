require 'pact_broker/api/decorators/base_decorator'
require 'pact_broker/api/decorators/triggered_webhook_decorator'

module PactBroker
  module Api
    module Decorators
      class TriggeredWebhooksDecorator < BaseDecorator
        collection :entries, as: :triggeredWebhooks, embedded: true, :extend => PactBroker::Api::Decorators::TriggeredWebhookDecorator

        link :self do | options |
          {
            title: options.fetch(:resource_title),
            href: options.fetch(:resource_url)
          }
        end
      end
    end
  end
end
