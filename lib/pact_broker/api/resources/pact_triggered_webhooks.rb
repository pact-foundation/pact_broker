require 'pact_broker/api/decorators/triggered_webhooks_decorator'

module PactBroker
  module Api
    module Resources
      class PactTriggeredWebhooks < BaseResource
        def allowed_methods
          ["GET"]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def resource_exists?
          !!pact
        end

        def to_json
          Decorators::TriggeredWebhooksDecorator.new(triggered_webhooks).to_json(decorator_options)
        end

        private

        def triggered_webhooks
          webhook_service.find_triggered_webhooks_for_pact(pact)
        end

        def resource_title
          "Webhooks triggered by the publication of the #{pact.name[0].downcase}#{pact.name[1..-1]}"
        end

        def decorator_options
          {
            user_options: decorator_context.merge(resource_title: resource_title)
          }
        end
      end
    end
  end
end
