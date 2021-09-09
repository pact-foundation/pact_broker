require "pact_broker/hash_refinements"

module PactBroker
  module Webhooks
    class ExecutionConfiguration
      using PactBroker::HashRefinements

      def initialize(params = {})
        @params = params
      end

      def with_updated_attribute(new_attribute)
        ExecutionConfiguration.new(params.deep_merge(new_attribute))
      end

      def with_show_response(value)
        with_updated_attribute(logging_options: { show_response: value })
      end

      def with_success_log_message(value)
        with_updated_attribute(logging_options: { success_log_message: value })
      end

      def with_failure_log_message(value)
        with_updated_attribute(logging_options: { failure_log_message: value })
      end

      def with_webhook_context(value)
        with_updated_attribute(webhook_context: value)
      end

      def with_retry_schedule(value)
        with_updated_attribute(retry_schedule: value)
      end

      def webhook_context
        self[:webhook_context]
      end

      def retry_schedule
        self[:retry_schedule]
      end

      def [](key)
        params[key]
      end

      def to_hash
        params
      end

      private

      attr_reader :params
    end
  end
end
