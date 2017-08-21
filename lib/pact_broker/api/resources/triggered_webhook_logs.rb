require 'pact_broker/api/resources/base_resource'
require 'pact_broker/webhooks/triggered_webhook'

module PactBroker
  module Api
    module Resources

      class TriggeredWebhookLogs < BaseResource

        def content_types_provided
          [["text/plain", :to_text]]
        end

        def allowed_methods
          ["GET"]
        end

        def resource_exists?
          triggered_webhook
        end

        def to_text
          # Too simple to bother putting into a service
          triggered_webhook.webhook_executions.collect(&:logs).join("\n")
        end

        def triggered_webhook
          @triggered_webhook ||= begin
            criteria = {webhook_uuid: identifier_from_path[:uuid], trigger_uuid: identifier_from_path[:trigger_uuid]}
            PactBroker::Webhooks::TriggeredWebhook.where(criteria).single_record
          end
        end
      end
    end
  end
end
