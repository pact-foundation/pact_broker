require 'pact_broker/webhooks/job'

module PactBroker
  module Webhooks
    describe Job do

      before do
        allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now)
      end

      let(:triggered_webhook) { instance_double("PactBroker::Webhooks::TriggeredWebhook", webhook_uuid: '1234') }

      context "when an error occurs for the first time" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now).and_raise("an error")
        end

        it "reschedules the job in 10 seconds" do
          expect(Job).to receive(:perform_in).with(10, {triggered_webhook: triggered_webhook, error_count: 1})
          Job.new.perform(triggered_webhook: triggered_webhook)
        end
      end

      context "when the webhook execution result is not successful for the first time" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now).and_return(instance_double("PactBroker::Domain::WebhookExecutionResult", success?: false))
        end

        it "reschedules the job in 10 seconds" do
          expect(Job).to receive(:perform_in).with(10, {triggered_webhook: triggered_webhook, error_count: 1})
          Job.new.perform(triggered_webhook: triggered_webhook)
        end
      end

      context "when an error occurs for the second time" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now).and_raise("an error")
        end

        it "reschedules the job in 60 seconds" do
          expect(Job).to receive(:perform_in).with(60, {triggered_webhook: triggered_webhook, error_count: 2  })
          Job.new.perform(triggered_webhook: triggered_webhook, error_count: 1)
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
      end

    end
  end
end
