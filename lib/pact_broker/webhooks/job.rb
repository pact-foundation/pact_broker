require 'sucker_punch'
require 'pact_broker/webhooks/service'
require 'pact_broker/logging'

module PactBroker
  module Webhooks
    class Job

      BACKOFF_TIMES = [10, 60, 120, 300, 600, 1200] #10 sec, 1 min, 2 min, 5 min, 10 min, 20 min => 38 minutes

      include SuckerPunch::Job
      include PactBroker::Logging

      def perform data
        @webhook = data[:webhook]
        @pact = data[:pact]
        @error_count = data[:error_count] || 0
        begin
          webhook_execution_result = PactBroker::Webhooks::Service.execute_webhook_now webhook, pact
          reschedule_job unless webhook_execution_result.success?
        rescue StandardError => e
          handle_error e
        end
      end

      private

      attr_reader :webhook, :pact, :error_count

      def handle_error e
        log_error e
        reschedule_job
      end

      def reschedule_job
        case error_count
        when 0...BACKOFF_TIMES.size
          logger.debug "Re-enqeuing job for webhook #{webhook.uuid} to run in #{BACKOFF_TIMES[error_count]} seconds"
          Job.perform_in(BACKOFF_TIMES[error_count], {webhook: webhook, pact: pact, error_count: error_count+1})
        else
          logger.error "Failed to execute webhook #{webhook.uuid} after #{BACKOFF_TIMES.size} times."
        end
      end

    end
  end
end
