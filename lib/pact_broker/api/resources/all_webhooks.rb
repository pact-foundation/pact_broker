require "pact_broker/services"
require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/webhooks_decorator"
require "pact_broker/api/decorators/webhook_decorator"
require "pact_broker/api/contracts/webhook_contract"

module PactBroker
  module Api
    module Resources
      class AllWebhooks < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "POST", "OPTIONS"]
        end

        def create_path
          webhook_url next_uuid, base_url
        end

        def post_is_create?
          true
        end

        def malformed_request?
          super || (request.post? && validation_errors_for_schema?)
        end

        def to_json
          decorator_class(:webhooks_decorator).new(webhooks).to_json(**decorator_options(resource_title: "Webhooks"))
        end

        def from_json
          saved_webhook = webhook_service.create(next_uuid, webhook, consumer, provider)
          response.body = decorator_class(:webhook_decorator).new(saved_webhook).to_json(**decorator_options)
        end

        def policy_name
          :'webhooks::webhooks'
        end

        def policy_record
          if request.post?
            webhook
          else
            nil
          end
        end

        private

        def schema
          api_contract_class(:webhook_contract)
        end

        def consumer
          webhook.consumer&.name ? pacticipant_service.find_pacticipant_by_name(webhook.consumer.name) : nil
        end

        def provider
          webhook.provider&.name ? pacticipant_service.find_pacticipant_by_name(webhook.provider.name) : nil
        end

        def webhooks
          webhook_service.find_all
        end

        def webhook
          @webhook ||= decorator_class(:webhook_decorator).new(PactBroker::Domain::Webhook.new).from_json(request_body)
        end

        def next_uuid
          @next_uuid ||= webhook_service.next_uuid
        end
      end
    end
  end
end
