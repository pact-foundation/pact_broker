# Formats a nested Hash of errors into application/problem+json format.
require "pact_broker/string_refinements"

module PactBroker
  module Api
    module Decorators
      class ValidationErrorsProblemJsonDecorator
        using PactBroker::StringRefinements


        # @param errors [Hash]
        def initialize(errors)
          @errors = errors
        end

        # @return [Hash]
        def to_hash(user_options:, **)
          error_list = []
          walk_errors(errors, error_list, "", user_options[:base_url])
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

        # The path is meant to be implemented using JSON Pointer, but this will probably do for now.
        # As per https://gregsdennis.github.io/Manatee.Json/usage/pointer.html
        # the only things that need to be escaped are "~" and "/", which are unlikely to be used
        # in a key name. You get what you deserve if you've done that.
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
          error = {
            "type" => "#{base_url}/problems/invalid-body-property-value",
            "title" => "Invalid body parameter",
            "detail" => message
          }
          error["pointer"] = path.tr(".", "/") if path.present?
          list << error
        end
      end
    end
  end
end
