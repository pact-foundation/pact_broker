require 'pact_broker/services'
require 'pact_broker/api/decorators/webhook_decorator'

module PactBroker
  module Api
    module Resources

      class Webhook < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "DELETE"]
        end

        def resource_exists?
          webhook
        end

        def to_json
          Decorators::WebhookDecorator.new(webhook).to_json(base_url: base_url)
        end

        def delete_resource
          webhook_service.delete_by_uuid uuid
          true
        end

        private

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