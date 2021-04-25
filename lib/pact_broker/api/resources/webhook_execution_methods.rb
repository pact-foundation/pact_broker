require 'pact_broker/webhooks/event_listener'

module PactBroker
  module Api
    module Resources
      module WebhookExecutionMethods
        def webhook_execution_configuration
          application_context.webhook_execution_configuration_creator.call(self)
        end

        def webhook_options
          {
            database_connector: database_connector,
            webhook_execution_configuration: webhook_execution_configuration
          }
        end

        def webhook_event_listener
          @webhook_event_listener ||= PactBroker::Webhooks::EventListener.new(webhook_options)
        end

        def handle_webhook_events
          Wisper.subscribe(webhook_event_listener) do
            result = yield
            schedule_triggered_webhooks
            result
          end
        end

        def schedule_triggered_webhooks
          webhook_event_listener.schedule_triggered_webhooks
        end
      end
    end
  end
end
