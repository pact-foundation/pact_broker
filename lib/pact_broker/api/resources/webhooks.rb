require 'pact_broker/services'
require 'pact_broker/api/decorators/webhooks_decorator'

module PactBroker::Api

  module Resources

    class Webhooks < BaseResource

      def content_types_provided
        [["application/hal+json", :to_json]]
      end

      def allowed_methods
        ["GET"]
      end

      def to_json
        Decorators::WebhooksDecorator.new(webhooks).to_json(base_url: resource_url)
      end

      def webhooks
        webhook_service.find_all
      end

    end
  end

end
