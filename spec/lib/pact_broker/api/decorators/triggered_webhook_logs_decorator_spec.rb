require "pact_broker/api/decorators/triggered_webhook_logs_decorator"

module PactBroker
  module Api
    module Decorators
      describe TriggeredWebhookLogsDecorator do
        let(:triggered_webhook) do
          double("PactBroker::Webhooks::TriggeredWebhook",
            uuid: "1234",
            webhook_executions: [webhook_execution],
            webhook: webhook
          )
        end

        let(:webhook) { double("webhook", uuid: "1234") }

        let(:webhook_execution) do
          instance_double(PactBroker::Webhooks::Execution, logs: "foo", success: true, created_at: td.in_utc { DateTime.new(2024, 1, 1) }  )
        end

        let(:user_options) { { base_url: "http://example.org" } }

        subject { TriggeredWebhookLogsDecorator.new(triggered_webhook).to_json(user_options: user_options) }

        it {
          Approvals.verify(subject, :name => "triggered_webhook_logs_decorator", format: :json)
        }
      end
    end
  end
end
