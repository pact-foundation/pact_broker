require_relative 'base_decorator'
require_relative 'timestamps'
require_relative 'pact_version_decorator'

module PactBroker
  module Api
    module Decorators

      class TriggeredWebhookDecorator < BaseDecorator
        property :request_description, as: :name
        property :status
        property :number_of_attempts_made, as: :attemptsMade
        property :number_of_attempts_remaining, as: :attemptsRemaining
        property :trigger_type, as: :triggerType

        property :created_at, as: :triggeredAt

        link :logs do | context |
          {
            href: triggered_webhook_logs_url(represented, context[:base_url]),
            title: "Webhook execution logs",
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

      class PactWebhooksStatusDecorator < BaseDecorator

        property :summary, exec_context: :decorator do
          property :success, as: :successful, default: 0
          property :failure, as: :failed, default: 0
          property :retrying
          property :not_run, as: :notRun
        end

        collection :entries, as: :triggeredWebhooks, embedded: true, :extend => TriggeredWebhookDecorator

        link :self do | context |
          {
            href: context[:resource_url],
            title: "Webhooks status"
          }
        end

        links :'pb:error-logs' do | context |
          triggered_webhooks_with_error_logs.collect do | triggered_webhook |
            {
              href: triggered_webhook_logs_url(triggered_webhook, context[:base_url]),
              title: "Error logs",
              name: triggered_webhook.request_description
            }
          end
        end

        link :'pb:pact-webhooks' do | context |
          {
            title: "Webhooks for the pact between #{context[:consumer_name]} and #{context[:provider_name]}",
            href: webhooks_for_pact_url(fake_consumer(context), fake_provider(context), context.fetch(:base_url))
          }
        end

        link :'pb:pact-version' do | context |
          if pact
            {
              href: pact_url(context[:base_url], pact),
              title: "Pact",
              name: pact.name
            }
          else
            nil
          end
        end

        link :'pb:consumer' do | context |
          {
            href: pacticipant_url(context[:base_url], fake_consumer(context)),
            title: "Consumer",
            name: context[:consumer_name]
          }
        end

        link :'pb:provider' do | context |
          {
            href: pacticipant_url(context[:base_url], fake_provider(context)),
            title: "Provider",
            name: context[:provider_name]
          }
        end

        def summary
          counts = represented.group_by(&:status).each_with_object({}) do | (status, triggered_webhooks), counts |
            counts[status] = triggered_webhooks.count
          end
          OpenStruct.new(counts)
        end

        def triggered_webhooks_with_error_logs
          represented.select{|w| w.failure? || w.retrying? }
        end

        def pact
          represented.any? ? represented.first.pact_publication : nil
        end

        def fake_consumer context
          OpenStruct.new(name: context[:consumer_name])
        end

        def fake_provider context
          OpenStruct.new(name: context[:provider_name])
        end
      end
    end
  end
end
