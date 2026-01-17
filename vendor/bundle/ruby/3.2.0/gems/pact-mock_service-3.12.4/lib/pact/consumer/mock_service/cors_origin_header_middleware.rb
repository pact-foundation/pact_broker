module Pact
  module Consumer
    class CorsOriginHeaderMiddleware

      def initialize app, cors_enabled
        @app = app
        @cors_enabled = cors_enabled
      end

      def call env
        response = @app.call env
        if env['HTTP_X_PACT_MOCK_SERVICE'] || @cors_enabled
          add_cors_header env, response
        else
          response
        end
      end

      def shutdown
        @app.shutdown
      end

      private

      def add_cors_header env, response
        cors_headers = { 'Access-Control-Allow-Origin' => env.fetch('HTTP_ORIGIN','*'), 'Access-Control-Allow-Credentials' => 'true'}
        [response[0], response[1].merge(cors_headers), response[2]]
      end
    end
  end
end
