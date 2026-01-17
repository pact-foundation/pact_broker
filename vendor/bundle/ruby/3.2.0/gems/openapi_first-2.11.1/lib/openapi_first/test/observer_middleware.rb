# frozen_string_literal: true

module OpenapiFirst
  module Test
    # Middleware that observes requests and responses. This is used to trigger hooks added by OpenapiFirst::Tests.
    class ObserverMiddleware
      def initialize(app, options = {})
        @app = app
        @definition = OpenapiFirst::Test[options.fetch(:api, :default)]
      end

      def call(env)
        request = Rack::Request.new(env)

        @definition.validate_request(request, raise_error: false)
        response = @app.call(env)
        status, headers, body = response
        @definition.validate_response(request, Rack::Response[status, headers, body], raise_error: false)
        response
      end
    end
  end
end
