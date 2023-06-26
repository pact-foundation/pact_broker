require "pact_broker/configuration"
require "securerandom"

# Logs the error
# Reports the error
# Generates and returns response headers and response body

module PactBroker
  module Api
    module Resources
      class ErrorHandler
        include PactBroker::Logging

        def initialize(error_logger, error_response_generator, error_reporter)
          @error_logger = error_logger
          @error_response_generator = error_response_generator
          @error_reporter = error_reporter
        end

        def call(error, env, message = nil)
          error_reference = PactBroker::Errors.generate_error_reference

          # log error
          error_logger.call(error, error_reference, env)

          # report error
          error_reporter.call(error, error_reference, env)


          # generate response
          headers, body = error_response_generator.call(error, error_reference, env, message: message)
          headers.each { | key, value | response.headers[key] = value }
          return headers, body
        end
      end
    end
  end
end
