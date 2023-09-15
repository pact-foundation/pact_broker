require "pact_broker/api/decorators/base_decorator"

# Decorates the individual validation error message Dry::Validation::Message

module PactBroker
  module Api
    module Decorators
      class EmbeddedErrorProblemJsonDecorator < BaseDecorator

        property :type, getter: -> (decorator:, user_options:, **) { decorator.type(user_options[:base_url]) }
        property :title, exec_context: :decorator
        property :text, as: :detail
        property :pointer, exec_context: :decorator
        property :parameter, exec_context: :decorator
        property :status, getter: -> (user_options:, **) { user_options[:status] || 400 }

        # dry-validation doesn't support validating a top level array, so we wrap
        # the json patch operations array in a hash with the key :_ops to validate it.
        # When we render the error, we have to remove the /_ops prefix from the pointer.
        # For contracts where we validate the path and the body together using _path and _body
        # we also need to remove the first key from the path.
        # It's possible the pointer should have a # at the start of it as per https://www.rfc-editor.org/rfc/rfc6901 :shrug:
        def pointer
          if is_path_error?
            nil
          # _ops, _path or _body for use when we need to hack the way dry-validation schemas work
          elsif represented.path.first.to_s.start_with?("_")
            "/" + represented.path[1..-1].join("/")
          else
            "/" + represented.path.join("/")
          end
        end

        def parameter
          if is_path_error?
            represented.path.last.to_s
          else
            nil
          end
        end

        def title
          if is_path_error?
            "Invalid path segment"
          else
            "Invalid body parameter"
          end
        end

        # @param [String] base_url
        def type(base_url)
          if is_path_error?
            "#{base_url}/#{path_type}"
          else
            "#{base_url}/#{body_type}"
          end
        end

        def path_type
          if represented.text.include?("missing")
            "problems/missing-request-parameter"
          elsif represented.text.include?("format")
            "problems/invalid-request-parameter-format"
          else
            "problems/invalid-request-parameter-value"
          end
        end

        def body_type
          if represented.text.include?("missing")
            "problems/missing-body-property"
          elsif represented.text.include?("format")
            "problems/invalid-body-property-format"
          else
            "problems/invalid-body-property-value"
          end
        end

        def is_path_error?
          represented.path.first == :_path
        end
      end
    end
  end
end
