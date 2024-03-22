require "pact_broker/webhooks/job"
require "pact_broker/webhooks/execution_configuration"

module PactBroker
  module Webhooks
    describe Job do
      before do
        allow(PactBroker::Webhooks::TriggerService).to receive(:execute_triggered_webhook_now).and_return(result)
        allow(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status)
        allow(PactBroker::Webhooks::TriggeredWebhook).to receive(:find).and_return(triggered_webhook)
        allow(Job).to receive(:logger).and_return(logger)
        allow(webhook_execution_configuration).to receive(:with_success_log_message).and_return(webhook_execution_configuration)
        allow(webhook_execution_configuration).to receive(:with_failure_log_message).and_return(webhook_execution_configuration)
      end

      let(:base_url) { "http://broker" }
      let(:triggered_webhook) { instance_double("PactBroker::Webhooks::TriggeredWebhook", webhook_uuid: "1234", id: 1, webhook: webhook) }
      let(:webhook) { double("webhook") }
      let(:result) { instance_double("PactBroker::Domain::WebhookExecutionResult", success?: success) }
      let(:webhook_execution_configuration) do
        instance_double(PactBroker::Webhooks::ExecutionConfiguration, retry_schedule: retry_schedule, to_hash: webhook_execution_configuration_hash)
      end
      let(:webhook_execution_configuration_hash) { { the: "options" } }
      let(:success) { true }
      let(:logger) { double("logger").as_null_object }
      let(:database_connector) { ->(&block) { block.call } }
      let(:webhook_context) { { the: "context" } }
      let(:retry_schedule) { [10, 60, 120, 300, 600, 1200] }
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
          allow(PactBroker::Webhooks::TriggerService).to receive(:execute_triggered_webhook_now).and_raise(error)
        end

        let(:error) { "an error" }

        context "when the error is HTTP related (most likely caused by a problem with the webhook or request itself)" do
          let(:error) { Errno::ECONNREFUSED.new }

          it "logs a message at info" do
            expect(logger).to receive(:info).with(/Error executing/, error)
            subject
          end
        end

        context "when the error is not HTTP related (most likely caused by a code, platform or environment issue)" do
          it "logs a message at warn" do
            expect(logger).to receive(:warn).with(/Error executing/, instance_of(RuntimeError))
            subject
          end
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
          expect(PactBroker::Webhooks::TriggerService).to receive(:execute_triggered_webhook_now)
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
          allow(PactBroker::Webhooks::TriggerService).to receive(:execute_triggered_webhook_now).and_raise("an error")
          job_params[:error_count] = 1
        end

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

          expect(PactBroker::Webhooks::TriggerService).to receive(:execute_triggered_webhook_now)
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

      context "when the triggered webhook gets deleted between executions" do
        before do
          allow(PactBroker::Webhooks::TriggeredWebhook).to receive(:find).and_return(nil)
        end

        it "does not reschedule the job" do
          expect(Job).to_not receive(:perform_in)
          expect(logger).to receive(:info).with(/Could not find webhook with id: 1/)
          subject
        end
      end

      context "when the webhook gets deleted between executions" do
        let(:webhook) { nil }

        it "updates the triggered_webhook status to 'failure'" do
          expect(PactBroker::Webhooks::Service).to receive(:update_triggered_webhook_status)
            .with(triggered_webhook, TriggeredWebhook::STATUS_FAILURE)
          subject
        end

        it "logs a message" do
          expect(logger).to receive(:info).with("Webhook with uuid 1234 cannot be executed it has been deleted. Marking triggered webhook as failed.")
          subject
        end

        it "does not reschedule the job" do
          expect(Job).to_not receive(:perform_in)
          subject
        end
      end
    end
  end
end
