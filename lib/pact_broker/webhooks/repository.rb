require 'sequel'
require 'pact_broker/domain/webhook'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/db'
require 'pact_broker/webhooks/webhook'
require 'pact_broker/webhooks/triggered_webhook'
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

      def find_by_consumer_and_provider_existing_at consumer, provider, date_time
        Webhook.where(consumer_id: consumer.id, provider_id: provider.id)
        .where(Sequel.lit("created_at < ?", date_time))
        .collect(&:to_domain)
      end

      def create_triggered_webhook trigger_uuid, webhook, pact, trigger_type
        db_webhook = Webhook.where(uuid: webhook.uuid).single_record
        TriggeredWebhook.create(
          status: TriggeredWebhook::STATUS_NOT_RUN,
          pact_publication_id: pact.id,
          webhook: db_webhook,
          webhook_uuid: db_webhook.uuid,
          trigger_uuid: trigger_uuid,
          trigger_type: trigger_type,
          consumer: db_webhook.consumer,
          provider: db_webhook.provider
        )
      end

      def update_triggered_webhook_status triggered_webhook, status
        triggered_webhook.update(status: status)
      end

      def create_execution triggered_webhook, webhook_execution_result
        Execution.create(
          triggered_webhook: triggered_webhook,
          success: webhook_execution_result.success?,
          logs: webhook_execution_result.logs)
      end

      def delete_triggered_webhooks_by_pacticipant pacticipant
        TriggeredWebhook.where(consumer: pacticipant).delete
        TriggeredWebhook.where(provider: pacticipant).delete
      end

      def delete_executions_by_pacticipant pacticipants
        # TODO this relationship no longer exists, deprecate in next version
        DeprecatedExecution.where(consumer: pacticipants).delete
        DeprecatedExecution.where(provider: pacticipants).delete
        execution_ids = Execution
          .join(:triggered_webhooks, {id: :triggered_webhook_id})
          .where(Sequel.or(
            Sequel[:triggered_webhooks][:consumer_id] => [*pacticipants].collect(&:id),
            Sequel[:triggered_webhooks][:provider_id] => [*pacticipants].collect(&:id),
          )).all.collect(&:id)
        Execution.where(id: execution_ids).delete
      end

      def unlink_triggered_webhooks_by_webhook_uuid uuid
        TriggeredWebhook.where(webhook: Webhook.where(uuid: uuid)).update(webhook_id: nil)
      end

      def find_webhook_executions_after date_time, consumer_id, provider_id
        Execution
          .select_all_qualified
          .join(:triggered_webhooks, {id: :triggered_webhook_id})
          .where(Sequel[:triggered_webhooks][:consumer_id] => consumer_id)
          .where(Sequel[:triggered_webhooks][:provider_id] => provider_id)
          .filter(Sequel[:webhook_executions][:created_at] > date_time)
          .all
      end
    end
  end
end
