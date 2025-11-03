
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
