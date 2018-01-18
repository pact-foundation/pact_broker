require 'pact_broker/services'
require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/webhooks_decorator'

module PactBroker
  module Api
    module Resources
      class AllWebhooks < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET"]
        end

        def to_json
          Decorators::WebhooksDecorator.new(webhooks).to_json(user_options: decorator_context(resource_title: "Webhooks"))
        end

        def webhooks
          webhook_service.find_all
        end
      end
    end
  end
end
