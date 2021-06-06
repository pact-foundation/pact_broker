require "pact_broker/api/resources/base_resource"
require "pact_broker/api/renderers/integrations_dot_renderer"
require "pact_broker/api/decorators/integrations_decorator"

module PactBroker
  module Api
    module Resources
      class Integrations < BaseResource
        def content_types_provided
          [
            ["text/vnd.graphviz", :to_dot],
            ["application/hal+json", :to_json]
          ]
        end

        def allowed_methods
          ["GET", "OPTIONS", "DELETE"]
        end

        def to_dot
          PactBroker::Api::Renderers::IntegrationsDotRenderer.call(integrations)
        end

        def to_json
          decorator_class(:integrations_decorator).new(integrations).to_json(decorator_options)
        end

        def integrations
          @integrations ||= integration_service.find_all
        end

        def delete_resource
          integration_service.delete_all
          true
        end

        def policy_name
          :'integrations::integrations'
        end
      end
    end
  end
end
