require "pact_broker/webhooks/http_request_with_redacted_headers"
require "pact_broker/webhooks/http_response_with_utf_8_safe_body"

module PactBroker
  module Webhooks
    class WebhookExecutionResult
      attr_reader :request, :response, :logs, :error

      def initialize(request, response, success, logs, error = nil)
        @request = PactBroker::Webhooks::HttpRequestWithRedactedHeaders.new(request)
        @response = response ? PactBroker::Webhooks::HttpResponseWithUtf8SafeBody.new(response) : nil
        @success = success
        @logs = logs
        @error = error
      end

      def success?
        @success
      end
    end
  end
end
