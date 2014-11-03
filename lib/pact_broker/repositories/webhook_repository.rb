require 'sequel'
require 'pact_broker/domain/webhook'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/db'
require 'pact_broker/repositories/webhook'


module PactBroker
  module Repositories

    class WebhookRepository

      include Repositories

      def create uuid, webhook, consumer, provider
        db_webhook = Webhook.from_domain webhook, consumer, provider
        db_webhook.uuid = uuid
        db_webhook.save
        webhook.request.headers.each_pair do | name, value |
          db_webhook.add_header WebhookHeader.from_domain(name, value, db_webhook.id)
        end
        find_by_uuid db_webhook.uuid
      end

      def find_by_uuid uuid
        Webhook.where(uuid: uuid).limit(1).collect(&:to_domain)[0]
      end

      def delete_by_uuid uuid
        Webhook.where(uuid: uuid).destroy
      end

      def delete_by_pacticipant pacticipant
        Webhook.where(consumer_id: pacticipant.id).destroy
        Webhook.where(provider_id: pacticipant.id).destroy
      end

      def find_all
        Webhook.all.collect(&:to_domain)
      end

      def find_by_consumer_and_provider consumer, provider
        Webhook.where(consumer_id: consumer.id, provider_id: provider.id).collect(&:to_domain)
      end

    end
  end
end