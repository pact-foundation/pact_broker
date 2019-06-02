require 'pact_broker/api/resources/base_resource'
require 'pact_broker/services'
require 'pact_broker/api/decorators/webhook_execution_result_decorator'
require 'pact_broker/constants'

module PactBroker
  module Api
    module Resources
      class WebhookExecution < BaseResource

        def allowed_methods
          ["POST", "OPTIONS"]
        end

        def process_post
          webhook_execution_result = webhook_service.test_execution(webhook, webhook_options)
          response.headers['Content-Type'] = 'application/hal+json;charset=utf-8'
          response.body = post_response_body webhook_execution_result
          true
        end

        def resource_exists?
          webhook
        end

        private

        def post_response_body webhook_execution_result
          Decorators::WebhookExecutionResultDecorator.new(webhook_execution_result).to_json(user_options: user_options)
        end

        def webhook
          @webhook ||= webhook_service.find_by_uuid uuid
        end

        def uuid
          identifier_from_path[:uuid]
        end

        def user_options
          {
            base_url: base_url,
            webhook: webhook,
            show_response: PactBroker.configuration.show_webhook_response?
          }
        end

        def webhook_options
          {
            logging_options: {
              show_response: PactBroker.configuration.show_webhook_response?
            },
            webhook_context: {
              base_url: base_url
            }
          }
        end
      end
    end
  end
end
