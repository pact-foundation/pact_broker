require 'sequel'
require 'pact_broker/models/webhook'
require 'pact_broker/db'

module PactBroker
  module Repositories
    class WebhookRepository

      def create webhook, consumer, provider
        PactBroker::DB.connection[:webhooks].
          insert(
            consumer_id: consumer.id,
            provider_id: provider.id,
            uuid: SecureRandom.urlsafe_base64,
            method: webhook.request.method,
            url: webhook.request.url,
            body: (String === webhook.request.body ? webhook.request.body : webhook.request.body.to_json)
          )

      end

    end
  end
end