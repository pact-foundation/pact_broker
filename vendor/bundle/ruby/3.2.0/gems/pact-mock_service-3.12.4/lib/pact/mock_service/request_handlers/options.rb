require 'pact/mock_service/request_handlers/base_request_handler'

module Pact
  module MockService
    module RequestHandlers
      class Options < BaseRequestHandler

        attr_reader :name, :logger, :cors_enabled

        HTTP_ACCESS_CONTROL_REQUEST_METHOD = "HTTP_ACCESS_CONTROL_REQUEST_METHOD".freeze
        HTTP_ACCESS_CONTROL_REQUEST_HEADERS = "HTTP_ACCESS_CONTROL_REQUEST_HEADERS".freeze
        ACCESS_CONTROL_ALLOW_CREDENTIALS = "Access-Control-Allow-Credentials".freeze
        ACCESS_CONTROL_ALLOW_ORIGIN = "Access-Control-Allow-Origin".freeze
        ACCESS_CONTROL_ALLOW_METHODS = "Access-Control-Allow-Methods".freeze
        ACCESS_CONTROL_ALLOW_HEADERS = "Access-Control-Allow-Headers".freeze
        AUTHORIZATION = "authorization".freeze
        COOKIE = "cookie".freeze
        HTTP_ORIGIN = "HTTP_ORIGIN".freeze
        ALL_METHODS = "DELETE, POST, GET, HEAD, PUT, TRACE, CONNECT, PATCH".freeze
        REQUEST_METHOD = "REQUEST_METHOD".freeze
        OPTIONS = "OPTIONS".freeze
        X_PACT_MOCK_SERVICE_REGEXP = /x-pact-mock-service/i

        def initialize name, logger, cors_enabled
          @name = name
          @logger = logger
          @cors_enabled = cors_enabled
        end

        def match? env
          is_options_request?(env) && (cors_enabled || is_administration_request?(env))
        end

        def respond env
          cors_headers = {
            ACCESS_CONTROL_ALLOW_ORIGIN => env.fetch(HTTP_ORIGIN,'*'),
            ACCESS_CONTROL_ALLOW_HEADERS => env.fetch(HTTP_ACCESS_CONTROL_REQUEST_HEADERS, '*'),
            ACCESS_CONTROL_ALLOW_METHODS => ALL_METHODS
          }

          if is_request_with_credentials?(env)
            cors_headers[ACCESS_CONTROL_ALLOW_CREDENTIALS] = "true"
          end

          logger.info "Received OPTIONS request for mock service administration endpoint #{env[HTTP_ACCESS_CONTROL_REQUEST_METHOD]} #{env['PATH_INFO']}. Returning CORS headers: #{cors_headers}."
          [200, cors_headers, []]
        end

        def is_options_request? env
          env[REQUEST_METHOD] == OPTIONS
        end

        def is_administration_request? env
          (env[HTTP_ACCESS_CONTROL_REQUEST_HEADERS] || '').match(X_PACT_MOCK_SERVICE_REGEXP)
        end

        def is_request_with_credentials? env
          headers = (env[HTTP_ACCESS_CONTROL_REQUEST_HEADERS] || '').split(",").map { |header| header.strip.downcase }
          headers.include?(AUTHORIZATION) || headers.include?(COOKIE)
        end
      end
    end
  end
end
