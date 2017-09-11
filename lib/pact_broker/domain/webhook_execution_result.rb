module PactBroker

  module Domain

    class WebhookExecutionResult

      def initialize response, logs, error = nil
        @response = response
        @logs = logs
        @error = error
      end

      def success?
        !@response.nil? && @response.code.to_i < 300
      end

      def response
        @response
      end

      def error
        @error
      end

      def logs
        @logs
      end
    end
  end
end
