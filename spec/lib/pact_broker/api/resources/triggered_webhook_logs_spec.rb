require "pact_broker/api/resources/triggered_webhook_logs"

module PactBroker
  module Api
    module Resources
      describe TriggeredWebhookLogs do
        before do
          td.create_pact_with_hierarchy
            .create_webhook(uuid: "5432")
            .create_triggered_webhook(uuid: "1234")
            .create_webhook_execution(logs: "foo")
            .create_webhook_execution(logs: "bar")
            .create_webhook(uuid: "5555")
            .create_triggered_webhook(uuid: "4321")
            .create_webhook_execution(logs: "waffle")
        end

        subject { get(path) }

        let(:triggered_webhook_uuid) { PactBroker::Webhooks::TriggeredWebhook.first.uuid }

        describe "by triggered webhook uuid" do
          let(:path) { "/triggered-webhooks/1234/logs" }

          it "returns the concatenated webhook execution logs" do
            expect(subject.body).to eq "foo\nbar"
          end
        end
      end
    end
  end
end
