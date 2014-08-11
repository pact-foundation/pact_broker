module PactBroker

  module Models

    class WebhookExecutionResult

      def initialize response, error = nil
        @response = response
        @error = error
      end

      def success?
        !@response.nil? && @response.code.to_i < 400
      end

      def response
        @response
      end

      def error
        @error
      end

    end
  end
end