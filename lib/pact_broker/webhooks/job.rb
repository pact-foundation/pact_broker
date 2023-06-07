require "sucker_punch"
require "pact_broker/webhooks/service"
require "pact_broker/logging"
require "pact_broker/webhooks/execution_configuration"

module PactBroker
  module Webhooks
    class Job

      INFO_ERROR_PREFIXES = %w{Errno:: Timeout:: Net:: OpenSSL:: EOFError SocketError}

      include SuckerPunch::Job
      include PactBroker::Logging

      def perform data
        data.fetch(:database_connector).call do
          perform_with_connection(data)
        end
      end

      private

      attr_reader :triggered_webhook, :error_count, :data

      def perform_with_connection(data)
        @data = data
        triggered_webhook_id = data[:triggered_webhook].id
        @triggered_webhook = PactBroker::Webhooks::TriggeredWebhook.find(id: triggered_webhook_id)
        if triggered_webhook
          perform_with_triggered_webhook
        else
          logger.info "Could not find webhook with id: #{triggered_webhook_id}"
        end
      end

      def perform_with_triggered_webhook
        @error_count = data[:error_count] || 0
        begin
          if triggered_webhook.webhook
            webhook_execution_result = PactBroker::Webhooks::TriggerService.execute_triggered_webhook_now(triggered_webhook, webhook_options(data))
            if webhook_execution_result.success?
              handle_success
            else
              handle_failure
            end
          else
            handle_webhook_deleted
          end
        rescue StandardError => e
          handle_error e
        end
      end

      def webhook_options(data)
        data[:webhook_execution_configuration]
          .with_success_log_message("Successfully executed webhook")
          .with_failure_log_message(failure_log_message)
          .to_hash
      end

      def failure_log_message
        if reschedule_job?
          "Retrying webhook in #{backoff_time} seconds"
        else
          "Webhook execution failed after #{retry_schedule.size + 1} attempts"
        end
      end

      def handle_error e
        message = "Error executing triggered webhook with ID #{triggered_webhook ? triggered_webhook.id : nil}"
        if e.class.name.start_with?(*INFO_ERROR_PREFIXES)
          logger.info(message, e)
        else
          logger.warn(message, e)
        end
        handle_failure
      end

      def handle_success
        update_triggered_webhook_status(TriggeredWebhook::STATUS_SUCCESS)
      end

      def handle_failure
        if reschedule_job?
          reschedule_job
          update_triggered_webhook_status(TriggeredWebhook::STATUS_RETRYING)
        else
          logger.info "Failed to execute webhook #{triggered_webhook.webhook_uuid} after #{retry_schedule.size + 1} attempts."
          update_triggered_webhook_status(TriggeredWebhook::STATUS_FAILURE)
        end
      end

      def handle_webhook_deleted
        logger.info("Webhook with uuid #{triggered_webhook.webhook_uuid} cannot be executed it has been deleted. Marking triggered webhook as failed.")
        update_triggered_webhook_status(TriggeredWebhook::STATUS_FAILURE)
      end

      def reschedule_job?
        error_count < retry_schedule.size
      end

      def reschedule_job
        logger.info "Re-enqeuing job for webhook #{triggered_webhook.webhook_uuid} to run in #{backoff_time} seconds"
        Job.perform_in(backoff_time, @data.merge(error_count: error_count+1))
      end

      def update_triggered_webhook_status status
        PactBroker::Webhooks::Service.update_triggered_webhook_status triggered_webhook, status
      end

      def backoff_time
        retry_schedule[error_count]
      end

      def retry_schedule
        data[:webhook_execution_configuration].retry_schedule
      end
    end
  end
end
