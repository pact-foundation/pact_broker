require "pact_broker/api/resources/base_resource"
require "pact_broker/services"
require "pact_broker/api/decorators/webhook_execution_result_decorator"
require "pact_broker/constants"
require "pact_broker/webhooks/execution_configuration"
require "pact_broker/api/resources/webhook_execution_methods"

module PactBroker
  module Api
    module Resources
      class WebhookExecution < BaseResource
        include WebhookExecutionMethods

        def content_types_provided
          [["application/hal+json"]]
        end

        def allowed_methods
          ["POST", "OPTIONS"]
        end

        def process_post
          webhook_execution_result = webhook_trigger_service.test_execution(webhook, webhook_execution_configuration.webhook_context, webhook_execution_configuration)
          response.headers["Content-Type"] = "application/hal+json;charset=utf-8"
          response.body = post_response_body(webhook_execution_result)
          true
        end

        def resource_exists?
          !!webhook
        end

        def malformed_request?
          if super
            true
          elsif request.post?
            if uuid
              false
            else
              validation_errors_for_schema?
            end
          else
            false
          end
        end

        def policy_name
          :'webhooks::webhook'
        end

        def action
          :execute
        end

        def policy_record
          webhook
        end

        private

        def post_response_body webhook_execution_result
          decorator_class(:webhook_execution_result_decorator).new(webhook_execution_result).to_json(**decorator_options)
        end

        def webhook
          @webhook ||= begin
            if uuid
              webhook_service.find_by_uuid uuid
            else
              build_unsaved_webhook
            end
          end
        end

        def uuid
          identifier_from_path[:uuid]
        end

        def decorator_options
          super(
            webhook: webhook,
            show_response: PactBroker.configuration.show_webhook_response?
          )
        end

        def build_unsaved_webhook
          decorator_class(:webhook_decorator).new(PactBroker::Domain::Webhook.new).from_json(request_body)
        end

        def schema
          api_contract_class(:webhook_contract)
        end
      end
    end
  end
end
