require 'sequel'
require 'pact_broker/models/webhook'
require 'pact_broker/db'

module PactBroker
  module Repositories
    class WebhookRepository

      def create webhook, consumer, provider
        uuid = SecureRandom.urlsafe_base64
        webhook_id = PactBroker::DB.connection[:webhooks].
          insert(
            consumer_id: consumer.id,
            provider_id: provider.id,
            uuid: uuid,
            method: webhook.request.method,
            url: webhook.request.url,
            body: (String === webhook.request.body ? webhook.request.body : webhook.request.body.to_json)
          )

        webhook.request.headers.each_pair do | name, value |
          PactBroker::DB.connection[:webhook_headers].insert(name: name, value: value, webhook_id: webhook_id)
        end

        webhook.uuid = uuid
        webhook.consumer = consumer
        webhook.provider = provider
        webhook
      end



    end
  end
end