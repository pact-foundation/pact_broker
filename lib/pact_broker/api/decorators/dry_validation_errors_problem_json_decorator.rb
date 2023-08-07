# Formats a Dry::Validation::MessageSet into application/problem+json format.

module PactBroker
  module Api
    module Decorators
      class DryValidationErrorsProblemJSONDecorator
        # @param errors [Dry::Validation::MessageSet]
        def initialize(errors)
          @errors = errors
        end

        # @return [Hash]
        def to_hash(user_options:, **)
          error_list = errors.collect{ |e| error_hash(e, user_options[:base_url]) }
          {
            "title" => "Validation errors",
            "type" => "#{user_options[:base_url]}/problems/validation-error",
            "status" => 400,
            "instance" => "/",
            "errors" => error_list
          }
        end

        # @return [String] JSON
        def to_json(*args, **kwargs)
          to_hash(*args, **kwargs).to_json
        end

        private

        attr_reader :errors

        def error_hash(error, base_url)
          {
            "type" => "#{base_url}/problems/invalid-body-property-value",
            "title" => "Validation error",
            "detail" => error.text,
            "pointer" => "/" + error.path.join("/"),
            "status" => 400
          }
        end
      end
    end
  end
end
