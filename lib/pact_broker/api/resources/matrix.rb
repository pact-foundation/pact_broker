require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/matrix_decorator'
require 'pact_broker/api/decorators/matrix_text_decorator'
require 'pact_broker/matrix/parse_query'

module PactBroker
  module Api
    module Resources
      class Matrix < BaseResource

        def initialize
          @selectors, @options = PactBroker::Matrix::ParseQuery.call(request.uri.query)
        end

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
          error_messages = matrix_service.validate_selectors(selectors)
          if error_messages.any?
            set_json_validation_error_messages error_messages
            true
          else
            false
          end
        end

        def to_json
          PactBroker::Api::Decorators::MatrixDecorator.new(lines).to_json(user_options: { base_url: base_url })
        end

        def to_text
          PactBroker::Api::Decorators::MatrixTextDecorator.new(lines).to_text(user_options: { base_url: base_url })
        end

        def lines
          @lines ||= matrix_service.find(selectors, options)
        end

        def selectors
          @selectors
        end

        def options
          @options
        end
      end
    end
  end
end
