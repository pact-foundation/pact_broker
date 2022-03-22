require "pact_broker/logging"

module PactBroker
  module Middleware
    class HttpDebugLogs
      include PactBroker::Logging

      EXCLUDE_HEADERS = ["puma.", "rack.", "pactbroker."]
      RACK_SESSION = "rack.session"

      def initialize(app)
        @app = app
        @logger = logger
      end

      def call(env)
        env_to_log = env.reject { | header, _ | header.start_with?(*EXCLUDE_HEADERS) }
        env_to_log["rack.session"] = env["rack.session"].to_hash if env["rack.session"]
        env_to_log["rack.input"] = request_body(env) if env["rack.input"]
        logger.debug("env", payload: env_to_log)
        status, headers, body = @app.call(env)
        logger.debug("response", payload: { "status" => status, "headers" => headers, "body" => body })
        [status, headers, body]
      end

      def request_body(env)
        buffer = env["rack.input"]
        request_body = buffer.read
        buffer.respond_to?(:rewind) && buffer.rewind
        JSON.parse(request_body) rescue request_body
      end
    end
  end
end
