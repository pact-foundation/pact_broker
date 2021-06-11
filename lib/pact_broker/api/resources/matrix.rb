require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/matrix_decorator"
require "pact_broker/api/decorators/matrix_text_decorator"
require "pact_broker/matrix/parse_query"

module PactBroker
  module Api
    module Resources
      class Matrix < BaseResource
        def content_types_provided
          [
            ["application/hal+json", :to_json],
            ["text/plain", :to_text]
          ]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def malformed_request?
          error_messages = matrix_service.validate_selectors(selectors, options)
          if error_messages.any?
            set_json_validation_error_messages error_messages
            true
          else
            false
          end
        end

        def to_json
          decorator_class(:matrix_decorator).new(results).to_json(decorator_options)
        end

        def to_text
          decorator_class(:matrix_text_decorator).new(results).to_text(decorator_options)
        end

        def policy_name
          :'matrix::matrix'
        end

        def results
          @results ||= matrix_service.find(selectors, options)
        end

        def parsed_query
          @parsed_query ||= PactBroker::Matrix::ParseQuery.call(request.uri.query)
        end

        def selectors
          parsed_query.first
        end

        def options
          parsed_query.last
        end
      end
    end
  end
end
