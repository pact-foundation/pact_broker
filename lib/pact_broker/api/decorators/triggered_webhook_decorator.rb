require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class TriggeredWebhookDecorator < BaseDecorator
        property :request_description, as: :name
        property :status
        property :number_of_attempts_made, as: :attemptsMade
        property :number_of_attempts_remaining, as: :attemptsRemaining
        property :trigger_type, as: :triggerType
        property :event_name, as: :eventName

        property :created_at, as: :triggeredAt

        link :'pb:logs' do | context |
          {
            href: triggered_webhook_logs_url(represented, context[:base_url]),
            title: "Webhook execution logs",
            name: represented.request_description
          }
        end

        link :logs do | context |
          {
            href: triggered_webhook_logs_url(represented, context[:base_url]),
            title: "DEPRECATED - Use pb:logs",
            name: represented.request_description
          }
        end

        link :'pb:webhook' do | context |
          {
            href: webhook_url(represented.webhook_uuid, context[:base_url]),
            title: "Webhook",
            name: represented.request_description
          }
        end
      end
    end
  end
end
