require 'pact_broker/api/resources/base_resource'
require 'pact_broker/services'
require 'pact_broker/api/decorators/webhook_decorator'

module PactBroker
  module Api
    module Resources

      class Webhook < BaseResource

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "PUT", "DELETE"]
        end

        def resource_exists?
          webhook
        end

        def malformed_request?
          if request.put?
            return invalid_json? || validation_errors?(webhook)
          end
          false
        end

        def from_json
          if webhook
            @webhook = webhook_service.update_by_uuid uuid, new_webhook
            response.body = to_json
          else
            404
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

        def validation_errors? webhook
          errors = webhook_service.errors(new_webhook)
          set_json_validation_error_messages(errors.messages) if !errors.empty?
          !errors.empty?
        end

        def webhook
          @webhook ||= webhook_service.find_by_uuid uuid
        end

        def new_webhook
          @new_webhook ||= Decorators::WebhookDecorator.new(PactBroker::Domain::Webhook.new).from_json(request_body)
        end

        def uuid
          identifier_from_path[:uuid]
        end
      end
    end
  end
end
