require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/triggered_webhooks_decorator'

module PactBroker
  module Api
    module Resources
      class PactTriggeredWebhooks < BaseResource
        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def resource_exists?
          !!pact
        end

        def to_json
          decorator_class(:triggered_webhooks_decorator).new(triggered_webhooks).to_json(decorator_options(resource_title: resource_title))
        end

        def policy_name
          :'webhooks::webhooks'
        end

        private

        def triggered_webhooks
          @webhooks ||= webhook_service.find_triggered_webhooks_for_pact(pact)
        end

        def resource_title
          "Webhooks triggered by the publication of the #{pact.name[0].downcase}#{pact.name[1..-1]}"
        end
      end
    end
  end
end
