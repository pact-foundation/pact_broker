# frozen_string_literal: true

module OpenapiFirst
  module Test
    # Return a Module with a call method that wrapps silent request/response validation to monitor a Rack app
    # This is used by Openapi::Test.observe
    module Callable
      # Returns a Module with a `call(env)` method that wraps super inside silent request/response validation
      # You can use this like `Application.prepend(OpenapiFirst::Test.app_module)` to monitor your app during testing.
      def self.[](definition)
        Module.new.tap do |mod|
          mod.define_method(:call) do |env|
            request = Rack::Request.new(env)

            definition.validate_request(request, raise_error: false)
            response = super(env)
            status, headers, body = response
            definition.validate_response(request, Rack::Response[status, headers, body], raise_error: false)
            response
          end
        end
      end
    end
  end
end
