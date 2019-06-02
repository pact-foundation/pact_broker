require 'pact_broker/webhooks/http_request_with_redacted_headers'
require 'pact_broker/webhooks/http_response_with_utf_8_safe_body'

module PactBroker
  module Webhooks
    class WebhookExecutionResult

      def initialize request, response, logs, error = nil
        @request = PactBroker::Webhooks::HttpRequestWithRedactedHeaders.new(request)
        @response = response ? PactBroker::Webhooks::HttpResponseWithUtf8SafeBody.new(response) : nil
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
