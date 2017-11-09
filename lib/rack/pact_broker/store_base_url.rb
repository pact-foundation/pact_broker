module Rack
  module PactBroker
    class StoreBaseURL
      def initialize app
        @app = app
      end

      def call(env)
        ENV['PACT_BROKER_BASE_URL'] ||= ::Rack::Request.new(env).base_url
        @app.call(env)
      end
    end
  end
end
