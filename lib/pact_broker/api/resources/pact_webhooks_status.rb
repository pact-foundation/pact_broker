require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/pact_webhooks_status_decorator"

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
          decorator_for(latest_triggered_webhooks).to_json(**decorator_options(identifier_from_path))
        end

        def policy_name
          :'pacts::pact'
        end

        def policy_record
          pact
        end

        private

        def latest_triggered_webhooks
          @latest_triggered_webhooks ||= webhook_service.find_latest_triggered_webhooks_for_pact(pact)
        end

        def pact
          @pact ||= pact_service.find_latest_pact(pact_params)
        end

        def webhooks
          @webhooks ||= webhook_service.find_by_consumer_and_provider(consumer, provider)
        end

        def decorator_for latest_triggered_webhooks
          decorator_class(:pact_webhooks_status_decorator).new(latest_triggered_webhooks)
        end
      end
    end
  end
end
