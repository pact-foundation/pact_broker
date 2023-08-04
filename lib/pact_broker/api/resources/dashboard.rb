require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/dashboard_decorator"
require "pact_broker/api/decorators/dashboard_text_decorator"
require "pact_broker/api/resources/pagination_methods"

module PactBroker
  module Api
    module Resources
      class Dashboard < BaseResource
        include PaginationMethods

        def content_types_provided
          [
            ["application/hal+json", :to_json],
            ["text/plain", :to_text],
          ]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def malformed_request?
          super || (request.get? && validation_errors_for_schema?(schema, request.query))
        end

        def to_json
          decorator_class(:dashboard_decorator).new(index_items).to_json(**decorator_options)
        end

        def to_text
          decorator_class(:dashboard_text_decorator).new(index_items).to_text(**decorator_options)
        end

        def policy_name
          :'dashboard::dashboard'
        end

        private

        def schema
          if request.get?
            PactBroker::Api::Contracts::PaginationQueryParamsSchema
          end
        end

        def index_items
          index_service.find_index_items_for_api(**identifier_from_path.merge(pagination_options))
        end
      end
    end
  end
end
