# Formats a nested Hash of errors as it comes out of the Dry Validation library
# into application/problem+json format.

module PactBroker
  module Api
    module Decorators
      class ValidationErrorsProblemJSONDecorator

        # @param errors [Hash]
        def initialize(errors)
          @errors = errors
        end

        # @return [Hash]
        def to_hash(decorator_options = {})
          error_list = []
          walk_errors(errors, error_list, "", decorator_options.dig(:user_options, :base_url))
          {
            "title" => "Validation errors",
            "type" => "#{decorator_options.dig(:user_options, :base_url)}/problems/validation-error",
            "status" => 400,
            "errors" => error_list
          }
        end

        # @return [String] JSON
        def to_json(decorator_options = {})
          to_hash(decorator_options).to_json
        end

        private

        attr_reader :errors

        def walk_errors(object, list, path, base_url)
          if object.is_a?(Hash)
            object.each { | key, value | walk_errors(value, list, "#{path}/#{key}", base_url) }
          elsif object.is_a?(Array)
            object.each { | value | walk_errors(value, list, path, base_url) }
          elsif object.is_a?(String)
            append_error(list, object, path, base_url)
          end
        end

        def append_error(list, message, path, base_url)
          list << {
            "type" => "#{base_url}/problems/invalid-body-property-value",
            "title" => "Validation error",
            "detail" => message,
            "instance" => path,
            "status" => 400
          }
        end
      end
    end
  end
end
