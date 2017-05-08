require 'pact_broker/webhooks/job'

module PactBroker
  module Webhooks
    describe Job do

      before do
        allow(PactBroker::Webhooks::Service).to receive(:execute_webhook_now)
      end

      let(:webhook) { double("webhook") }

      context "when an error occurs for the first time" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_webhook_now).and_raise("an error")
        end

        it "reschedules the job in 10 seconds" do
          expect(Job).to receive(:perform_in).with(10, {webhook: webhook, error_count: 1})
          Job.new.perform(webhook: webhook)
        end
      end

      context "when an error occurs for the second time" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_webhook_now).and_raise("an error")
        end

        it "reschedules the job in 60 seconds" do
          expect(Job).to receive(:perform_in).with(60, {webhook: webhook, error_count: 2  })
          Job.new.perform(webhook: webhook, error_count: 1)
        end
      end

      context "when an error occurs for the last time" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_webhook_now).and_raise("an error")
        end

        it "does not reschedule the job" do
          expect(Job).to_not receive(:perform_in)
          Job.new.perform(webhook: webhook, error_count: 6)
        end
      end

    end
  end
end
