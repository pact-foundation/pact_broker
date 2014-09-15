
require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/webhook_decorator'
require 'pact_broker/api/decorators/webhooks_decorator'

module PactBroker

  module Api
    module Resources

      class PactWebhooks < BaseResource

        def allowed_methods
          ["POST", "GET"]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def resource_exists?
          (@consumer = find_pacticipant(identifier_from_path[:consumer_name], "consumer")) &&
            (@provider = find_pacticipant(identifier_from_path[:provider_name], "provider"))
        end

        def malformed_request?
          if request.post?
            return invalid_json? || validation_errors?(webhook)
          end
          false
        end

        def process_post
          saved_webhook = webhook_service.create webhook, consumer, provider
          response.headers['Content-Type'] = 'application/json'
          response.headers['Location'] = webhook_url saved_webhook, base_url
          response.body = Decorators::WebhookDecorator.new(saved_webhook).to_json(base_url: base_url)
          true
        end

        def to_json
          Decorators::WebhooksDecorator.new(webhooks).to_json(decorator_context(resource_title: 'Pact webhooks'))
        end

        private

        attr_reader :consumer, :provider

        def webhooks
          webhook_service.find_by_consumer_and_provider consumer, provider
        end

        def webhook
          @webhook ||= Decorators::WebhookDecorator.new(PactBroker::Models::Webhook.new).from_json(request.body.to_s)
        end

        def find_pacticipant name, role
          pacticipant = pacticipant_service.find_pacticipant_by_name name
          if pacticipant.nil?
            set_json_error_message "No #{role} with name '#{name}' found"
            nil
          else
            pacticipant
          end
        end

      end
    end
  end
end