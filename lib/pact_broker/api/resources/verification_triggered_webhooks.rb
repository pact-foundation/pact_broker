require 'pact_broker/api/decorators/triggered_webhooks_decorator'

module PactBroker
  module Api
    module Resources
      class VerificationTriggeredWebhooks < BaseResource
        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def resource_exists?
          !!verification
        end

        def to_json
          Decorators::TriggeredWebhooksDecorator.new(triggered_webhooks).to_json(decorator_options)
        end

        private

        def triggered_webhooks
          webhook_service.find_triggered_webhooks_for_verification(verification)
        end

        def resource_title
          "Webhooks triggered by the publication of verification result #{verification.number}"
        end

        def decorator_options
          {
            user_options: decorator_context.merge(resource_title: resource_title)
          }
        end

        def verification
          @verification ||= verification_service.find(identifier_from_path)
        end
      end
    end
  end
end
