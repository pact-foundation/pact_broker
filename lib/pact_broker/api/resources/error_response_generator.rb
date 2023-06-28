require "pact_broker/configuration"
require "pact_broker/api/decorators/runtime_error_problem_json_decorator"
require "pact_broker/errors"
require "pact_broker/messages"

module PactBroker
  module Api
    module Resources
      class ErrorResponseGenerator
        include PactBroker::Logging
        extend PactBroker::Messages

        # @param error [StandardError]
        # @param error_reference [String] an error reference to display to the user
        # @param env [Hash] the rack env
        # @return [Hash, String] the response headers to set, the response body to set
        def self.call(error, error_reference, env, message: nil)
          body = response_body_hash(error, error_reference, env, display_message(error, message, obfuscated_error_message(error_reference)))
          return headers(env), body.to_json
        end

        def self.display_message(error, message, obfuscated_message)
          if message
            message
          elsif PactBroker.configuration.show_backtrace_in_error_response?
            error.message || obfuscated_message
          else
            PactBroker::Errors.reportable_error?(error) ? obfuscated_message : error.message
          end
        end

        private_class_method def self.response_body_hash(error, error_reference, env, message)
          if problem_json?(env)
            problem_json_response_body(message, env)
          else
            hal_json_response_body(error, error_reference, message)
          end
        end

        private_class_method def self.hal_json_response_body(error, error_reference, message)
          response_body = {
            error: {
              message: message,
              reference: error_reference
            }
          }
          if PactBroker.configuration.show_backtrace_in_error_response?
            response_body[:error][:backtrace] = error.backtrace
          end
          response_body
        end

        private_class_method def self.problem_json_response_body(message, env)
          PactBroker::Api::Decorators::RuntimeErrorProblemJSONDecorator.new(message).to_hash(user_options: { base_url: env["pactbroker.base_url" ] })
        end

        private_class_method def self.obfuscated_error_message(error_reference)
          message("errors.runtime.with_error_reference", error_reference: error_reference)
        end

        private_class_method def self.headers(env)
          if problem_json?(env)
            { "Content-Type" => "application/problem+json;charset=utf-8" }
          else
            { "Content-Type" => "application/hal+json;charset=utf-8" }
          end
        end

        private_class_method def self.problem_json?(env)
          env["HTTP_ACCEPT"]&.include?("application/problem+json")
        end
      end
    end
  end
end
