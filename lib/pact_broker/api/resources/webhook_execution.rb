require 'pact_broker/services'
require 'pact_broker/api/decorators/webhook_execution_result_decorator'

module PactBroker
  module Api
    module Resources

      class WebhookExecution < BaseResource

        def allowed_methods
          ["POST"]
        end

        def process_post
          webhook_execution_result = webhook_service.execute_webhook_now webhook
          response.headers['Content-Type'] = 'application/hal+json;charset=utf-8'
          response.body = post_response_body webhook_execution_result
          webhook_execution_result.success? ? true : 500
        end

        def resource_exists?
          webhook
        end

        private

        def post_response_body webhook_execution_result
          Decorators::WebhookExecutionResultDecorator.new(webhook_execution_result).to_json(user_options: { base_url: base_url, webhook: webhook })
        end

        def webhook
          @webhook ||= webhook_service.find_by_uuid uuid
        end

        def uuid
          identifier_from_path[:uuid]
        end
      end
    end
  end

end
