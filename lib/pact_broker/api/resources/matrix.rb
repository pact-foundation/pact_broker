require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/matrix_decorator'
require 'pact_broker/matrix/parse_query'

module PactBroker
  module Api
    module Resources
      class Matrix < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET"]
        end

        def malformed_request?
          error_messages = matrix_service.validate_selectors(criteria)
          if error_messages.any?
            set_json_validation_error_messages error_messages
            true
          else
            false
          end
        end

        def to_json
          lines = matrix_service.find(criteria)
          PactBroker::Api::Decorators::MatrixPactDecorator.new(lines).to_json(user_options: { base_url: base_url })
        end

        def criteria
          @criteria ||= PactBroker::Matrix::ParseQuery.call(request.uri.query)
        end
      end
    end
  end
end
