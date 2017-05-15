require 'uri'

# This class is for https://github.com/pact-foundation/pact_broker/issues/101
# curl -i "http://127.0.0.1:9292/<script>"

module Rack
  module PactBroker
    class InvalidUriProtection

      def initialize app
        @app = app
      end

      def call env
        if valid_uri? env
          @app.call(env)
        else
          [404, {}, []]
        end
      end

      def valid_uri? env
        begin
          parse(::Rack::Request.new(env).url)
          true
        rescue URI::InvalidURIError
          false
        end
      end

      def parse uri
        URI.parse(uri)
      end
    end
  end
end
