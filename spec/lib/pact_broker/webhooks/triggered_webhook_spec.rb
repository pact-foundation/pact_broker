require "pact_broker/webhooks/triggered_webhook"

module PactBroker
  module Webhooks
    describe TriggeredWebhook do
      let(:status) { TriggeredWebhook::STATUS_SUCCESS }

      subject { TriggeredWebhook.new(status: status) }

      describe "remaining_attempts" do
        before do
          PactBroker.configuration.webhook_retry_schedule = [1, 1, 1]
          allow(subject).to receive(:webhook_executions).and_return([double("execution")])
        end

        its(:number_of_attempts_made) { is_expected.to eq 1 }

        context "when its status is retrying" do
          let(:status) { TriggeredWebhook::STATUS_RETRYING }
          its(:number_of_attempts_remaining) { is_expected.to eq 3  }
        end

        context "when its status is not_run" do
          let(:status) { TriggeredWebhook::STATUS_NOT_RUN }
          its(:number_of_attempts_remaining) { is_expected.to eq 3  }
        end

        context "when its status is success" do
          let(:status) { TriggeredWebhook::STATUS_SUCCESS }
          its(:number_of_attempts_remaining) { is_expected.to eq 0}
        end

        context "when its status is failure" do
          let(:status) { TriggeredWebhook::STATUS_FAILURE }
          its(:number_of_attempts_remaining) { is_expected.to eq 0}
        end
      end
    end
  end
end
