
module PactBroker
  module Api
    module Resources
      class Integrations < BaseResource
        include PaginationMethods
        include FilterMethods

        def content_types_provided
          [
            ["text/vnd.graphviz", :to_dot],
            ["application/hal+json", :to_json]
          ]
        end

        def allowed_methods
          ["GET", "OPTIONS", "DELETE"]
        end

        def malformed_request?
          super || (request.get? && validation_errors_for_schema?(schema, request.query))
        end

        def to_dot
          integrations = integration_service.find_all(filter_options, pagination_options)
          PactBroker::Api::Renderers::IntegrationsDotRenderer.call(integrations)
        end

        def to_json
          integrations = integration_service.find_all(filter_options, pagination_options, decorator_class(:integrations_decorator).eager_load_associations)
          decorator_class(:integrations_decorator).new(integrations).to_json(**decorator_options)
        end

        def delete_resource
          integration_service.delete_all
          true
        end

        def policy_name
          :'integrations::integrations'
        end

        def schema
          if request.get?
            PactBroker::Api::Contracts::PaginationQueryParamsSchema
          end
        end
      end
    end
  end
end
