require_relative 'base_decorator'
require 'pact_broker/api/decorators/webhook_decorator'

module PactBroker
  module Api
    module Decorators
      class WebhooksDecorator < BaseDecorator

        # collection :entries, embedded: true, as: :webhooks, :extend => PactBroker::Api::Decorators::WebhookDecorator

        links :webhooks do | options |
          represented.entries.collect do | webhook |
            {
              title: webhook.description,
              href: webhook_url(webhook, options.fetch(:base_url))
            }
          end
        end
      end
    end
  end
end