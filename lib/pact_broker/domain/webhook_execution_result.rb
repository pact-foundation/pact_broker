module PactBroker
  module Domain
    class WebhookExecutionResult

      def initialize request, response, logs, error = nil
        @request = request
        @response = response
        @logs = logs
        @error = error
      end

      def success?
        !@response.nil? && @response.code.to_i < 300
      end

      def request
        @request
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
