module Rack
  module PactBroker
    class AddCacheHeader
      def initialize app
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)
        [status, { "Cache-Control" => "no-cache" }.merge(headers || {}), body]
      end
    end
  end
end
