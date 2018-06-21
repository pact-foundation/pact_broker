require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/webhook_decorator'
require 'pact_broker/api/decorators/webhooks_decorator'
require 'pact_broker/api/contracts/webhook_contract'

module PactBroker
  module Api
    module Resources
      class Webhooks < BaseResource

        def allowed_methods
          ["POST", "GET", "OPTIONS"]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def resource_exists?
          (identifier_from_path[:consumer_name].nil? || consumer) &&
            (identifier_from_path[:provider_name].nil? || provider)
        end

        def malformed_request?
          if request.post?
            return invalid_json? || validation_errors?(webhook)
          end
          false
        end

        def validation_errors? webhook
          errors = webhook_service.errors(webhook)

          unless errors.empty?
            response.headers['Content-Type'] = 'application/hal+json;charset=utf-8'
            response.body = { errors: errors.messages }.to_json
          end

          !errors.empty?
        end

        def create_path
          webhook_url next_uuid, base_url
        end

        def post_is_create?
          true
        end

        def from_json
          saved_webhook = webhook_service.create next_uuid, webhook, consumer, provider
          response.body = Decorators::WebhookDecorator.new(saved_webhook).to_json(user_options: { base_url: base_url })
        end

        def to_json
          Decorators::WebhooksDecorator.new(webhooks).to_json(user_options: decorator_context(resource_title: 'Pact webhooks'))
        end

        private

        def webhooks
          webhook_service.find_by_consumer_and_provider consumer, provider
        end

        def webhook
          @webhook ||= Decorators::WebhookDecorator.new(PactBroker::Domain::Webhook.new).from_json(request_body)
        end

        def next_uuid
          @next_uuid ||= webhook_service.next_uuid
        end

        def consumer
          @consumer ||= identifier_from_path[:consumer_name] && find_pacticipant(identifier_from_path[:consumer_name], "consumer")
        end

        def provider
          @provider ||= identifier_from_path[:provider_name] && find_pacticipant(identifier_from_path[:provider_name], "provider")
        end

        def find_pacticipant name, role
          pacticipant_service.find_pacticipant_by_name(name).tap do | pacticipant |
            set_json_error_message("No #{role} with name '#{name}' found") if pacticipant.nil?
          end
        end
      end
    end
  end
end
