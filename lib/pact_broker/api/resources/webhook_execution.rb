require 'pact_broker/api/resources/base_resource'
require 'pact_broker/services'
require 'pact_broker/api/decorators/webhook_execution_result_decorator'
require 'pact_broker/constants'

module PactBroker
  module Api
    module Resources

      class WebhookExecution < BaseResource

        def allowed_methods
          ["POST"]
        end

        def process_post
          webhook_execution_result = webhook_service.execute_webhook_now webhook, pact
          response.headers['Content-Type'] = 'application/hal+json;charset=utf-8'
          response.body = post_response_body webhook_execution_result
          if webhook_execution_result.success?
            true
          else
            response.headers[PactBroker::DO_NOT_ROLLBACK] = 'true'
            500
          end
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

        def pact
          @pact ||= pact_service.find_latest_pact consumer_name: webhook.consumer_name, provider_name: webhook.provider_name
        end

        def uuid
          identifier_from_path[:uuid]
        end
      end
    end
  end

end
