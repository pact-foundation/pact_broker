# frozen_string_literal: true
require "securerandom"
require "semantic_logger"

module Rack
  module PactBroker
    # Establishes the per request logging context, so that every log entry
    # emitted while handling a request can be correlated.
    #
    # SemanticLogger ships no Rack integration - its Rack middleware lives in the
    # Rails coupled rails_semantic_logger gem - so this is the integration point
    # for a plain Rack application.
    #
    # Deliberately does not log the request. Access logging is a separate
    # concern, generally handled by the web server, and emitting it here would
    # duplicate those records.
    class RequestContext
      RACK_REQUEST_ID_HEADER = "HTTP_X_REQUEST_ID"
      HTTP_REQUEST_ID_HEADER = "x-request-id"

      # Checked in order, so X-Request-Id wins when a caller sends both.
      # X-Correlation-Id is the same idea under a different name, and is what
      # many gateways and non-Ruby stacks send.
      RACK_INBOUND_ID_HEADERS = [RACK_REQUEST_ID_HEADER, "HTTP_X_CORRELATION_ID"].freeze

      # An inbound request id is only trusted if it matches this charset and
      # length. It is echoed verbatim into the response header and into every
      # log line for the request, so anything outside a conservative
      # token-safe charset (in particular CRLF or other control characters,
      # which could forge log entries or split the response) is rejected in
      # favour of generating a fresh id.
      VALID_REQUEST_ID = /\A[a-zA-Z0-9\-_.]+\z/
      MAX_REQUEST_ID_LENGTH = 128

      def initialize(app)
        @app = app
      end

      def call(env)
        request_id = inbound_request_id(env) || SecureRandom.hex(16)

        SemanticLogger.tagged(request_id: request_id) do
          status, headers, body = @app.call(env.merge(RACK_REQUEST_ID_HEADER => request_id))
          [status, headers.merge(HTTP_REQUEST_ID_HEADER => request_id), body]
        end
      end

      private

      def inbound_request_id(env)
        RACK_INBOUND_ID_HEADERS.each do | header |
          valid = valid_inbound_request_id(env[header])
          return valid if valid
        end
        nil
      end

      def valid_inbound_request_id(value)
        return nil unless value.is_a?(String)
        return nil if value.empty? || value.length > MAX_REQUEST_ID_LENGTH
        return nil unless value.match?(VALID_REQUEST_ID)

        value
      end
    end
  end
end
