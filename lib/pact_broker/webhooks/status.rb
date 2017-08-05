module PactBroker
  module Webhooks
    class Status

      def initialize webhooks, webhook_executions
        @webhooks = webhooks
        @webhook_executions = webhook_executions
      end

      def to_s
        to_sym.to_s
      end

      def to_sym
        return :none if webhooks.empty?
        return :not_run if webhook_executions.empty?
        most_recent_execution.success ? :success : :failed
      end

      private

      attr_reader :webhooks, :webhook_executions

      def most_recent_execution
        webhook_executions.sort.last
      end
    end
  end
end
