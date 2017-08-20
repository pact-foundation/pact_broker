require 'pact_broker/webhooks/job'

module PactBroker
  module Webhooks
    describe Job do

      before do
        allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now)
        allow(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status)
      end

      let(:triggered_webhook) { instance_double("PactBroker::Webhooks::TriggeredWebhook", webhook_uuid: '1234') }

      context "when the job succeeds" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now).and_return(instance_double("PactBroker::Domain::WebhookExecutionResult", success?: true))
        end

        subject { Job.new.perform(triggered_webhook: triggered_webhook) }

        it "does not reschedule the job" do
          expect(Job).to_not receive(:perform_in)
          subject
        end

        it "updates the triggered_webhook status to 'success'" do
          expect(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status).with(triggered_webhook, TriggeredWebhook::STATUS_SUCCESS)
          subject
        end
      end

      context "when an error occurs for the first time" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now).and_raise("an error")
        end

        subject { Job.new.perform(triggered_webhook: triggered_webhook) }

        it "reschedules the job in 10 seconds" do
          expect(Job).to receive(:perform_in).with(10, {triggered_webhook: triggered_webhook, error_count: 1})
          subject
        end

        it "updates the triggered_webhook status to 'retrying'" do
          expect(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status).with(triggered_webhook, TriggeredWebhook::STATUS_RETRYING)
          subject
        end
      end

      context "when the webhook execution result is not successful for the first time" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now).and_return(instance_double("PactBroker::Domain::WebhookExecutionResult", success?: false))
        end

        subject { Job.new.perform(triggered_webhook: triggered_webhook) }

        it "reschedules the job in 10 seconds" do
          expect(Job).to receive(:perform_in).with(10, {triggered_webhook: triggered_webhook, error_count: 1})
          subject
        end

        it "updates the triggered_webhook status to 'retrying'" do
          expect(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status).with(triggered_webhook, TriggeredWebhook::STATUS_RETRYING)
          subject
        end
      end

      context "when an error occurs for the second time" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now).and_raise("an error")
        end

        subject { Job.new.perform(triggered_webhook: triggered_webhook, error_count: 1) }

        it "reschedules the job in 60 seconds" do
          expect(Job).to receive(:perform_in).with(60, {triggered_webhook: triggered_webhook, error_count: 2})
          subject
        end

        it "updates the triggered_webhook status to 'retrying'" do
          expect(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status).with(triggered_webhook, TriggeredWebhook::STATUS_RETRYING)
          subject
        end
      end

      context "when an error occurs for the last time" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now).and_raise("an error")
        end

        subject { Job.new.perform(triggered_webhook: triggered_webhook, error_count: 6) }

        it "does not reschedule the job" do
          expect(Job).to_not receive(:perform_in)
          subject
        end

        it "logs that it has failed" do
          allow(Job.logger).to receive(:error)
          expect(Job.logger).to receive(:error).with(/Failed to execute/)
          subject
        end

        it "updates the triggered_webhook status to 'failed'" do
          expect(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status).with(triggered_webhook, TriggeredWebhook::STATUS_FAILURE)
          subject
        end
      end
    end
  end
end
