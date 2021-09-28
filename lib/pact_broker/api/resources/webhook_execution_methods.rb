require "pact_broker/webhooks/event_listener"
require "pact_broker/events/subscriber"

module PactBroker
  module Api
    module Resources
      module WebhookExecutionMethods
        def handle_webhook_events(event_context = {})
          @webhook_event_listener = PactBroker::Webhooks::EventListener.new(webhook_options(event_context))
          PactBroker::Events.subscribe(webhook_event_listener) do
            yield
          end
        end

        def schedule_triggered_webhooks
          webhook_event_listener&.schedule_triggered_webhooks
        end

        def finish_request
          if response.code < 400
            schedule_triggered_webhooks
          end
          super
        end


        def webhook_options(event_context = {})
          {
            database_connector: database_connector,
            webhook_execution_configuration: webhook_execution_configuration.with_webhook_context(event_context)
          }
        end
        private :webhook_options

        def webhook_execution_configuration
          application_context.webhook_execution_configuration_creator.call(self)
        end
        private :webhook_execution_configuration

        def webhook_event_listener
          @webhook_event_listener
        end

        private :webhook_event_listener
      end
    end
  end
end
