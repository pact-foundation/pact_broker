require 'pact_broker/webhooks/job'
require 'pact_broker/webhooks/execution_configuration'

module PactBroker
  module Webhooks
    describe Job do
      before do
        PactBroker.configuration.webhook_retry_schedule = [10, 60, 120, 300, 600, 1200]
        allow(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now).and_return(result)
        allow(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status)
        allow(PactBroker::Webhooks::TriggeredWebhook).to receive(:find).and_return(triggered_webhook)
        allow(Job).to receive(:logger).and_return(logger)
        allow(webhook_execution_configuration).to receive(:with_success_log_message).and_return(webhook_execution_configuration)
        allow(webhook_execution_configuration).to receive(:with_failure_log_message).and_return(webhook_execution_configuration)
      end

      let(:base_url) { "http://broker" }
      let(:triggered_webhook) { instance_double("PactBroker::Webhooks::TriggeredWebhook", webhook_uuid: '1234', id: 1) }
      let(:result) { instance_double("PactBroker::Domain::WebhookExecutionResult", success?: success) }
      let(:webhook_execution_configuration) { instance_double(PactBroker::Webhooks::ExecutionConfiguration, to_hash: webhook_execution_configuration_hash) }
      let(:webhook_execution_configuration_hash) { { the: 'options' } }
      let(:success) { true }
      let(:logger) { double('logger').as_null_object }
      let(:database_connector) { ->(&block) { block.call } }
      let(:webhook_context) { { the: "context" } }
      let(:job_params) do
        {
          triggered_webhook: triggered_webhook,
          database_connector: database_connector,
          webhook_execution_configuration: webhook_execution_configuration
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
          expect(Job).to receive(:perform_in).with(10, hash_including(job_params))
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

        it "sets the success and failure messages" do
          expect(webhook_execution_configuration).to receive(:with_success_log_message).with("Successfully executed webhook")
          expect(webhook_execution_configuration).to receive(:with_failure_log_message).with("Retrying webhook in 10 seconds")
          subject

        end

        it "executes the job with an log message indicating that the webhook will be retried" do
          expect(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now)
            .with(triggered_webhook, webhook_execution_configuration_hash)
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
        before do
          job_params[:error_count] = 6
        end

        let(:success) { false }

        it "executes the job with an log message indicating that the webhook has failed" do
          expect(webhook_execution_configuration).to receive(:with_failure_log_message).with("Webhook execution failed after 7 attempts")
          expect(webhook_execution_configuration).to receive(:with_success_log_message).with("Successfully executed webhook")

          expect(PactBroker::Webhooks::Service).to receive(:execute_triggered_webhook_now)
            .with(triggered_webhook, webhook_execution_configuration_hash)
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
