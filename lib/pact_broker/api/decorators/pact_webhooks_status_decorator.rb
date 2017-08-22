require_relative 'base_decorator'
require_relative 'timestamps'
require_relative 'pact_version_decorator'

module PactBroker
  module Api
    module Decorators

      class TriggeredWebhookDecorator < BaseDecorator
        property :status
        property :trigger_type, as: :triggerType
        include Timestamps

        link :logs do | context |
          {
            href: triggered_webhook_logs_url(represented, context[:base_url]),
            title: "Webhook execution logs",
            name: represented.request_description
          }
        end
      end

      class PactWebhooksStatusDecorator < BaseDecorator

        property :success

        # property :webhook_summary, as: :webhookSummary do
        #   property :successful
        #   property :failed
        #   property :retrying
        #   property :not_run, as: :notRun
        # end

        collection :triggered_webhooks, as: :triggeredWebhooks, embedded: true, :extend => TriggeredWebhookDecorator

        link :self do | context |
          {
            href: context[:resource_url],
            title: "Webhooks status"
          }
        end

        link :'pb:consumer' do | context |
          {
            href: pacticipant_url(context[:base_url], OpenStruct.new(name: context[:consumer_name])),
            title: "Consumer",
            name: context[:consumer_name]
          }
        end

        link :'pb:provider' do | context |
          {
            href: pacticipant_url(context[:base_url], OpenStruct.new(name: context[:provider_name])),
            title: "Provider",
            name: context[:provider_name]
          }
        end
      end
    end
  end
end
