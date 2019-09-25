require_relative 'base_decorator'
require 'pact_broker/api/decorators/webhook_decorator'

module PactBroker
  module Api
    module Decorators
      class WebhooksDecorator < BaseDecorator

        link :self do | context |
          {
            title: context[:resource_title],
            href: context[:resource_url]
          }
        end

        link :'pb:create' do | context |
          {
            title: "POST to create a webhook",
            href: context[:resource_url]
          }
        end

        links :'pb:webhooks' do | context |
          represented.entries.collect do | webhook |
            {
              title: webhook.scope_description,
              name: webhook.display_description,
              href: webhook_url(webhook.uuid, context[:base_url])
            }
          end
        end

        curies do | context |
          [{
            name: :pb,
            href: context[:base_url] + '/doc/webhooks-{rel}',
            templated: true
          }]
        end
      end
    end
  end
end