require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/pact_webhooks_status_decorator'

module PactBroker

  module Api
    module Resources

      class PactWebhooksStatus < BaseResource

        def allowed_methods
          ["GET"]
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
          @latest_triggered_webhooks ||= webhook_service.find_latest_triggered_webhooks(consumer, provider)
        end

        def pact
          @pact ||= pact_service.find_latest_pact(pact_params)
        end

        def webhooks
          webhook_service.find_by_consumer_and_provider consumer, provider
        end

        def consumer
          @consumer ||= find_pacticipant(identifier_from_path[:consumer_name], "consumer")
        end

        def provider
          @provider ||= find_pacticipant(identifier_from_path[:provider_name], "provider")
        end

        def find_pacticipant name, role
          pacticipant_service.find_pacticipant_by_name(name).tap do | pacticipant |
            set_json_error_message("No #{role} with name '#{name}' found") if pacticipant.nil?
          end
        end

        def decorator_for latest_triggered_webhooks
          PactBroker::Api::Decorators::PactWebhooksStatusDecorator.new(latest_triggered_webhooks)
        end
      end
    end
  end
end
