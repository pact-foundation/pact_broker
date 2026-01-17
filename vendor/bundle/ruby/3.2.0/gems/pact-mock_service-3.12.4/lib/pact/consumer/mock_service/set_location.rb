module Pact
  module Consumer
    class SetLocation

      LOCATION = 'X-Pact-Mock-Service-Location'.freeze
      HTTP_X_PACT_MOCK_SERVICE = 'HTTP_X_PACT_MOCK_SERVICE'

      def initialize app, base_url
        @app = app
        @location_header = {LOCATION => base_url}.freeze
      end

      def call env
        response = @app.call(env)
        env[HTTP_X_PACT_MOCK_SERVICE] ? add_location_header_to_response(response) : response
      end

      def add_location_header_to_response response
        [response.first, response[1].merge(@location_header), response.last]
      end

      def shutdown
        @app.shutdown
      end

    end
  end
end
