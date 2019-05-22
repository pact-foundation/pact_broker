require 'pact_broker/webhooks/job'

module PactBroker
  module Webhooks
    describe Job do
      before do
        PactBroker.configuration.webhook_retry_schedule = [10, 60, 120, 300, 600, 1200]
        allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now).and_return(result)
        allow(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status)
        allow(PactBroker::Webhooks::TriggeredWebhook).to receive(:find).and_return(triggered_webhook)
        allow(Job).to receive(:logger).and_return(logger)
      end

      let(:base_url) { "http://broker" }
      let(:triggered_webhook) { instance_double("PactBroker::Webhooks::TriggeredWebhook", webhook_uuid: '1234', id: 1) }
      let(:result) { instance_double("PactBroker::Domain::WebhookExecutionResult", success?: success)}
      let(:success) { true }
      let(:logger) { double('logger').as_null_object }
      let(:database_connector) { ->(&block) { block.call } }
      let(:webhook_context) { { the: "context" } }
      let(:job_params) do
        {
          triggered_webhook: triggered_webhook,
          database_connector: database_connector,
          webhook_context: webhook_context,
          execution_options: { the: 'options' }
        }
      end

      subject { Job.new.perform(job_params) }

      it "reloads the TriggeredWebhook object to make sure it has a fresh copy" do
        expect(PactBroker::Webhooks::TriggeredWebhook).to receive(:find).with(id: 1)
        subject
      end

      context "when the job succeeds" do
        it "does not reschedule the job" do
          expect(Job).to_not receive(:perform_in)
          subject
        end

        it "updates the triggered_webhook status to 'success'" do
          expect(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status)
            .with(triggered_webhook, TriggeredWebhook::STATUS_SUCCESS)
          subject
        end
      end

      context "when an error occurs for the first time" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now).and_raise("an error")
        end

        it "reschedules the job in 10 seconds" do
          expect(Job).to receive(:perform_in).with(10, hash_including(error_count: 1))
          subject
        end

        it "reschedules the job with the passed in data" do
          expect(Job).to receive(:perform_in).with(10, hash_including(
            webhook_context: webhook_context,
            database_connector: database_connector,
            triggered_webhook: triggered_webhook
          ))
          subject
        end

        it "updates the triggered_webhook status to 'retrying'" do
          expect(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status)
            .with(triggered_webhook, TriggeredWebhook::STATUS_RETRYING)
          subject
        end
      end

      context "when the webhook execution result is not successful for the first time" do
        let(:success) { false }

        it "reschedules the job in 10 seconds" do
          expect(Job).to receive(:perform_in).with(10, hash_including(error_count: 1))
          subject
        end

        it "executes the job with an log message indicating that the webhook will be retried" do
          expect(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now)
            .with(triggered_webhook, {
              execution_options: {
                failure_log_message: "Retrying webhook in 10 seconds",
                success_log_message: "Successfully executed webhook",
                the: 'options'
              },
              webhook_context: webhook_context
          })
          subject
        end

        it "updates the triggered_webhook status to 'retrying'" do
          expect(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status)
            .with(triggered_webhook, TriggeredWebhook::STATUS_RETRYING)
          subject
        end
      end

      context "when an error occurs for the second time" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now).and_raise("an error")
          job_params[:error_count] = 1
        end

        # subject { Job.new.perform(triggered_webhook: triggered_webhook, error_count: 1, database_connector: database_connector, base_url: base_url) }

        it "reschedules the job in 60 seconds" do
          expect(Job).to receive(:perform_in).with(60, hash_including(error_count: 2))
          subject
        end

        it "updates the triggered_webhook status to 'retrying'" do
          expect(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status)
            .with(triggered_webhook, TriggeredWebhook::STATUS_RETRYING)
          subject
        end
      end

      context "when the job is not successful for the last time" do
        let(:success) { false }
        before do
          job_params[:error_count] = 6
        end

        # subject { Job.new.perform(triggered_webhook: triggered_webhook, error_count: 6, database_connector: database_connector, base_url: base_url) }

        it "executes the job with an log message indicating that the webhook has failed" do
          expect(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now)
            .with(triggered_webhook, hash_including(
              execution_options: hash_including(
                failure_log_message: "Webhook execution failed after 7 attempts",
                success_log_message: "Successfully executed webhook")
            )
          )
          subject
        end

        it "does not reschedule the job" do
          expect(Job).to_not receive(:perform_in)
          subject
        end

        it "logs that it has failed" do
          allow(Job.logger).to receive(:info)
          expect(Job.logger).to receive(:info).with(/Failed to execute/)
          subject
        end

        it "updates the triggered_webhook status to 'failed'" do
          expect(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status).with(triggered_webhook, TriggeredWebhook::STATUS_FAILURE)
          subject
        end
      end

      context "when the webhook gets deleted between executions" do
        before do
          allow(PactBroker::Webhooks::TriggeredWebhook).to receive(:find).and_return(nil)
        end

        it "does not reschedule the job" do
          expect(Job).to_not receive(:perform_in)
          expect(logger).to receive(:info).with(/Could not find webhook with id: 1/)
          subject
        end
      end
    end
  end
end
