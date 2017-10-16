require 'pact_broker/api/resources/triggered_webhook_logs'

module PactBroker
  module Api
    module Resources
      describe TriggeredWebhookLogs do

        let(:td) { TestDataBuilder.new }

        before do
          td.create_pact_with_hierarchy
            .create_webhook(uuid: "5432")
            .create_triggered_webhook(trigger_uuid: "1234")
            .create_webhook_execution(logs: "foo")
            .create_webhook_execution(logs: "bar")
        end

        let(:path) { "/webhooks/5432/trigger/1234/logs" }

        subject { get path; last_response }

        it "returns the concatenated webhook execution logs" do
          expect(subject.body).to eq "foo\nbar"
        end
      end
    end
  end
end
