require 'pact_broker/domain/webhook_request'

module PactBroker
  module Webhooks
    class HttpRequestWithRedactedHeaders < SimpleDelegator
      def to_hash
        __getobj__().to_hash.each_with_object({}) do | (key, values), new_hash |
          new_hash[key] = redact?(key) ? ["**********"] : values
        end
      end

      def method
        __getobj__().method
      end

      def redact? name
        PactBroker::Domain::WebhookRequest::HEADERS_TO_REDACT.any?{ | pattern | name =~ pattern }
      end
    end
  end
end
