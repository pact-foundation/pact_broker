require 'sequel'
require 'pact_broker/domain/webhook'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/db'
require 'pact_broker/webhooks/webhook'
require 'pact_broker/webhooks/triggered_webhook'
require 'pact_broker/webhooks/latest_triggered_webhook'
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

      def update_by_uuid uuid, webhook
        existing_webhook = Webhook.find(uuid: uuid)
        existing_webhook.update_from_domain(webhook).save
        existing_webhook.headers.collect(&:delete)
        webhook.request.headers.each_pair do | name, value |
          existing_webhook.add_header PactBroker::Webhooks::WebhookHeader.from_domain(name, value, existing_webhook.id)
        end
        find_by_uuid uuid
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
        DeprecatedExecution.where(webhook_id: Webhook.where(uuid: uuid).select(:id)).update(webhook_id: nil)
      end

      def delete_triggered_webhooks_by_pact_publication_id pact_publication_id
        triggered_webhook_ids = TriggeredWebhook.where(pact_publication_id: pact_publication_id).select_for_subquery(:id)
        Execution.where(triggered_webhook_id: triggered_webhook_ids).delete
        TriggeredWebhook.where(id: triggered_webhook_ids).delete
        DeprecatedExecution.where(pact_publication_id: pact_publication_id).delete
      end

      def find_latest_triggered_webhooks consumer, provider
        LatestTriggeredWebhook
          .where(consumer: consumer, provider: provider)
          .order(:id)
          .all
          .group_by{|w| [w.consumer_id, w.provider_id, w.webhook_uuid]}
          .values
          .collect(&:last)
      end

      def fail_retrying_triggered_webhooks
        TriggeredWebhook.retrying.update(status: TriggeredWebhook::STATUS_FAILURE)
      end
    end
  end
end
