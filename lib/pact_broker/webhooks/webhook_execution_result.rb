require 'pact_broker/webhooks/http_request_with_redacted_headers'
require 'pact_broker/webhooks/http_response_with_utf_8_safe_body'

module PactBroker
  module Webhooks
    class WebhookExecutionResult
      attr_reader :request, :response, :logs, :error

      def initialize(request, response, logs, error = nil)
        @request = PactBroker::Webhooks::HttpRequestWithRedactedHeaders.new(request)
        @response = response ? PactBroker::Webhooks::HttpResponseWithUtf8SafeBody.new(response) : nil
        @logs = logs
        @error = error
      end

      def success?
        if response
          # Response HTTP Code must be in success list otherwise it is false
          PactBroker.configuration.webhook_http_code_success.include? response.code.to_i
        else
          false
        end
      end
    end
  end
end
