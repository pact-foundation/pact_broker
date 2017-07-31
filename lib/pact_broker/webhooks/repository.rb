require 'sequel'
require 'pact_broker/domain/webhook'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/db'
require 'pact_broker/webhooks/webhook'
require 'pact_broker/webhooks/execution'

module PactBroker
  module Webhooks

    class Repository

      include Repositories

      def create uuid, webhook, consumer, provider
        db_webhook = Webhook.from_domain webhook, consumer, provider
        db_webhook.uuid = uuid
        db_webhook.save
        webhook.request.headers.each_pair do | name, value |
          db_webhook.add_header PactBroker::Webhooks::WebhookHeader.from_domain(name, value, db_webhook.id)
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

      def create_execution webhook, webhook_execution_result
        db_webhook = Webhook.where(uuid: webhook.uuid).single_record
        execution = Execution.create(
          webhook: db_webhook,
          webhook_uuid: db_webhook.uuid,
          consumer: db_webhook.consumer,
          provider: db_webhook.provider,
          success: webhook_execution_result.success?,
          logs: webhook_execution_result.logs)
      end

      def delete_executions_by_pacticipant pacticipant
        Execution.where(consumer: pacticipant).delete
        Execution.where(provider: pacticipant).delete
      end

      def unlink_executions_by_webhook_uuid uuid
        Execution.where(webhook: Webhook.where(uuid: uuid)).update(webhook_id: nil)
      end

      def find_webhook_executions_after date_time, consumer_id, provider_id
        Execution
          .where(consumer_id: consumer_id, provider_id: provider_id)
          .where(Sequel.lit("created_at > ?", date_time)).all
      end
    end
  end
end
