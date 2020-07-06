require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/pact_webhooks_status_decorator'

module PactBroker
  module Api
    module Resources
      class PactWebhooksStatus < BaseResource

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def resource_exists?
          consumer && provider
        end

        def to_json
          decorator_for(latest_triggered_webhooks).to_json(user_options: decorator_context(identifier_from_path))
        end

        private

        def latest_triggered_webhooks
          @latest_triggered_webhooks ||= webhook_service.find_latest_triggered_webhooks_for_pact(pact)
        end

        def pact
          @pact ||= pact_service.find_latest_pact(pact_params)
        end

        def webhooks
          webhook_service.find_by_consumer_and_provider(consumer, provider)
        end

        def decorator_for latest_triggered_webhooks
          PactBroker::Api::Decorators::PactWebhooksStatusDecorator.new(latest_triggered_webhooks)
        end
      end
    end
  end
end
