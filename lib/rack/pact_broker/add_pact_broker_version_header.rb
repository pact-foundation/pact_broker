require "pact_broker/version"

module Rack
  module PactBroker
    class AddPactBrokerVersionHeader

      X_PACT_BROKER_VERSION = "X-Pact-Broker-Version".freeze

      def initialize app
        @app = app
      end

      def call env
        response = @app.call(env)
        [response[0], add_version_header(response[1]), response[2]]
      end

      def add_version_header headers
        headers.merge(X_PACT_BROKER_VERSION => ::PactBroker::VERSION)
      end
    end
  end
end
