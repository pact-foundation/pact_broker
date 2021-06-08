require "pact_broker/api/resources/base_resource"
require "pact_broker/webhooks/triggered_webhook"

module PactBroker
  module Api
    module Resources
      class TriggeredWebhookLogs < BaseResource

        def content_types_provided
          [["text/plain", :to_text]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          !!triggered_webhook
        end

        def to_text
          # Too simple to bother putting into a service
          if webhook_executions.any?
            webhook_executions.collect(&:logs).join("\n")
          else
            "Webhook has not executed yet. Please retry in a few seconds."
          end
        end

        def policy_name
          :'webhooks::webhook'
        end

        def policy_record
          triggered_webhook&.webhook
        end

        private

        def webhook_executions
          @webhook_executions ||= triggered_webhook.webhook_executions
        end

        def triggered_webhook
          @triggered_webhook ||= PactBroker::Webhooks::TriggeredWebhook.find(uuid: identifier_from_path[:uuid])
        end
      end
    end
  end
end
