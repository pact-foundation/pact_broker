require 'pact_broker/api/resources/base_resource'
require 'pact_broker/services'
require 'pact_broker/api/decorators/webhook_decorator'
require 'pact_broker/api/resources/webhook_resource_methods'

module PactBroker
  module Api
    module Resources
      class Webhook < BaseResource

        include WebhookResourceMethods

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "PUT", "DELETE", "OPTIONS"]
        end

        def resource_exists?
          webhook
        end

        def malformed_request?
          if request.put?
            return invalid_json? || webhook_validation_errors?(parsed_webhook, uuid)
          end
          false
        end

        def from_json
          if webhook
            @webhook = webhook_service.update_by_uuid uuid, params_with_string_keys
            response.body = to_json
          else
            @webhook = webhook_service.create(uuid, parsed_webhook, consumer, provider)
            response.body = to_json
            201
          end
        end

        def to_json
          Decorators::WebhookDecorator.new(webhook).to_json(user_options: { base_url: base_url })
        end

        def delete_resource
          webhook_service.delete_by_uuid uuid
          true
        end

        private

        def webhook
          @webhook ||= webhook_service.find_by_uuid uuid
        end

        def parsed_webhook
          @parsed_webhook ||= Decorators::WebhookDecorator.new(PactBroker::Domain::Webhook.new).from_json(request_body)
        end

        def uuid
          identifier_from_path[:uuid]
        end
      end
    end
  end
end
