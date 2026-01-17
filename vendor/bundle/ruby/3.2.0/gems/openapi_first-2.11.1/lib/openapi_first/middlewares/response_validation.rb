# frozen_string_literal: true

require 'rack'

module OpenapiFirst
  module Middlewares
    # A Rack middleware to validate requests against an OpenAPI API description
    class ResponseValidation
      # @param spec [String, OpenapiFirst::Definition] Path to the OpenAPI file or an instance of Definition
      # @param options Hash
      #   :spec [String, OpenapiFirst::Definition] Path to the OpenAPI file or an instance of Definition.
      #         This will be deprecated. Please use spec argument instead.
      #   :raise_error [Boolean] Whether to raise an error if validation fails. default: true
      def initialize(app, spec = nil, options = {})
        @app = app
        if spec.is_a?(Hash)
          options = spec
          spec = options.fetch(:spec)
        end
        @raise = options.fetch(:raise_error, OpenapiFirst.configuration.response_validation_raise_error)

        raise "You have to pass spec: when initializing #{self.class}" unless spec

        @definition = spec.is_a?(Definition) ? spec : OpenapiFirst.load(spec)
      end

      # @attr_reader [Proc] app The upstream Rack application
      attr_reader :app

      def call(env)
        status, headers, body = @app.call(env)
        @definition.validate_response(Rack::Request.new(env), Rack::Response[status, headers, body],
                                      raise_error: @raise)
        [status, headers, body]
      end
    end
  end
end
