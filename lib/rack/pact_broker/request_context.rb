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
      HTTP_REQUEST_ID_HEADER = "X-Request-Id"

      def initialize(app)
        @app = app
      end

      def call(env)
        request_id = env[RACK_REQUEST_ID_HEADER] || SecureRandom.hex(16)

        SemanticLogger.tagged(request_id: request_id) do
          status, headers, body = @app.call(env.merge(RACK_REQUEST_ID_HEADER => request_id))
          [status, headers.merge(HTTP_REQUEST_ID_HEADER => request_id), body]
        end
      end
    end
  end
end
