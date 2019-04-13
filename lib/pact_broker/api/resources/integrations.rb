require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/renderers/integrations_dot_renderer'

module PactBroker
  module Api
    module Resources
      class Integrations < BaseResource
        def content_types_provided
          [["text/vnd.graphviz", :to_dot]]
        end

        def allowed_methods
          ["GET", "OPTIONS", "DELETE"]
        end

        def to_dot
          PactBroker::Api::Renderers::IntegrationsDotRenderer.call(integrations)
        end

        def integrations
          pact_service.find_latest_pacts
        end

        def delete_resource
          integration_service.delete(consumer_name, provider_name)
          true
        end
      end
    end
  end
end
