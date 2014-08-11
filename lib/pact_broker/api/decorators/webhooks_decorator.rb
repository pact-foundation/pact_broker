require_relative 'base_decorator'
require 'pact_broker/api/decorators/webhook_decorator'

module PactBroker
  module Api
    module Decorators
      class WebhooksDecorator < BaseDecorator


        link :self do | context |
          {
            title: context.resource_title,
            href: context.resource_url
          }
        end

        links :webhooks do | context |
          represented.entries.collect do | webhook |
            {
              title: webhook.description,
              name: webhook.request_description,
              href: webhook_url(webhook, context.base_url)
            }
          end
        end
      end
    end
  end
end