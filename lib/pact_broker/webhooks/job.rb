require 'sucker_punch'
require 'pact_broker/webhooks/service'
require 'pact_broker/logging'

module PactBroker
  module Webhooks
    class Job

      include SuckerPunch::Job
      include PactBroker::Logging

      def perform data
        @webhook = data[:webhook]
        @error_count = data[:error_count] || 0
        begin
          PactBroker::Webhooks::Service.execute_webhook_now webhook
        rescue StandardError => e
          handle_error e
        end
      end

      private

      attr_reader :webhook, :error_count

      def handle_error e
        logger.log_error e
        backoff_times = [10, 60, 120, 300, 600, 1200] #10 sec, 1 min, 2 min, 5 min, 10 min, 20 min => 38 minutes
        case error_count
        when 0...backoff_times.size
          logger.debug "Re-enqeuing job to run in #{backoff_times[error_count]} seconds"
          Job.perform_in(backoff_times[error_count], {webhook: webhook, error_count: error_count+1})
        else
          logger.error "Failed to execute webhook after #{backoff_times.size} times."
        end
      end

    end
  end
end
