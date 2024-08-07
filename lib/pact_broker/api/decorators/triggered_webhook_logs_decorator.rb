require_relative "base_decorator"

module PactBroker
  module Api
    module Decorators
      class TriggeredWebhookLogsDecorator < BaseDecorator
        class WebhookExecutionDecorator < BaseDecorator
          property  :success
          property  :logs
          property  :created_at, as: :createdAt
        end


        nested :triggeredWebhook, embedded: true do
          property :uuid
        end

        collection :webhook_executions, as: :executions, :class => PactBroker::Webhooks::Execution, :extend => WebhookExecutionDecorator

        link :self do | options |
          {
            title: "Triggered webhook logs",
            href: options[:resource_url]
          }
        end

        link :'pb:webhook' do | context |
          if represented.webhook
            {
              href: webhook_url(represented.webhook.uuid, context[:base_url]),
              title: "Webhook"
            }
          end
        end
      end
    end
  end
end
