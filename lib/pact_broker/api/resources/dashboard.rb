require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/dashboard_decorator'
require 'pact_broker/api/decorators/dashboard_text_decorator'

module PactBroker
  module Api
    module Resources
      class Dashboard < BaseResource
        def content_types_provided
          [
            ["application/hal+json", :to_json],
            ["text/plain", :to_text],
          ]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def to_json
          PactBroker::Api::Decorators::DashboardDecorator.new(index_items).to_json(decorator_options)
        end

        def to_text
          PactBroker::Api::Decorators::DashboardTextDecorator.new(index_items).to_text(decorator_options)
        end

        def policy_name
          :'dashboard::dashboard'
        end

        private

        def index_items
          index_service.find_index_items_for_api(identifier_from_path)
        end
      end
    end
  end
end
