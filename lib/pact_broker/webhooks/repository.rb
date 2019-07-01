require 'sequel'
require 'pact_broker/domain/webhook'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/db'
require 'pact_broker/webhooks/webhook'
require 'pact_broker/webhooks/webhook_event'
require 'pact_broker/webhooks/triggered_webhook'
require 'pact_broker/webhooks/latest_triggered_webhook'
require 'pact_broker/webhooks/execution'
require 'pact_broker/logging'

module PactBroker
  module Webhooks
    class Repository
      include PactBroker::Logging

      include Repositories

      def create uuid, webhook, consumer, provider
        db_webhook = Webhook.from_domain webhook, consumer, provider
        db_webhook.uuid = uuid
        db_webhook.save
        (webhook.events || []).each do | webhook_event |
          db_webhook.add_event(webhook_event)
        end
        find_by_uuid db_webhook.uuid
      end

      def find_by_uuid uuid
        Webhook.where(uuid: uuid).limit(1).collect(&:to_domain)[0]
      end

      def update_by_uuid uuid, webhook
        existing_webhook = Webhook.find(uuid: uuid)
        existing_webhook.consumer_id = webhook.consumer ? pacticipant_repository.find_by_name(webhook.consumer.name).id : nil
        existing_webhook.provider_id = webhook.provider ? pacticipant_repository.find_by_name(webhook.provider.name).id : nil
        existing_webhook.update_from_domain(webhook).save
        existing_webhook.events.collect(&:delete)
        (webhook.events || []).each do | webhook_event |
          existing_webhook.add_event(webhook_event)
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

      def find_for_pact pact
        find_by_consumer_and_or_provider(pact.consumer, pact.provider)
      end

      def find_by_consumer_and_or_provider consumer, provider
        find_by_consumer_and_provider(consumer, provider) +
          find_by_consumer_and_provider(nil, provider) +
          find_by_consumer_and_provider(consumer, nil) +
          find_by_consumer_and_provider(nil, nil)
      end

      def find_by_consumer_and_provider consumer, provider
        criteria = {
          consumer_id: (consumer ? consumer.id : nil),
          provider_id: (provider ? provider.id : nil)
        }
        Webhook.where(criteria).collect(&:to_domain)
      end

      def delete_by_consumer_and_provider consumer, provider
        Webhook.where(consumer: consumer, provider: provider).destroy
      end

      def find_by_consumer_and_or_provider_and_event_name consumer, provider, event_name
        find_by_consumer_and_provider_and_event_name(consumer, provider, event_name) +
          find_by_consumer_and_provider_and_event_name(nil, provider, event_name) +
          find_by_consumer_and_provider_and_event_name(consumer, nil, event_name) +
          find_by_consumer_and_provider_and_event_name(nil, nil, event_name)
      end

      def find_by_consumer_and_provider_and_event_name consumer, provider, event_name
        criteria = {
          consumer_id: (consumer ? consumer.id : nil),
          provider_id: (provider ? provider.id : nil)
        }
        Webhook
          .select_all_qualified
          .enabled
          .where(criteria)
          .join(:webhook_events, { webhook_id: :id })
          .where(Sequel[:webhook_events][:name] => event_name)
          .collect(&:to_domain)
      end

      # TODO delete
      def find_by_consumer_and_provider_existing_at consumer, provider, date_time
        Webhook.where(consumer_id: consumer.id, provider_id: provider.id)
        .where(Sequel.lit("created_at < ?", date_time))
        .collect(&:to_domain)
      end

      def create_triggered_webhook trigger_uuid, webhook, pact, verification, trigger_type
        db_webhook = Webhook.where(uuid: webhook.uuid).single_record
        TriggeredWebhook.create(
          status: TriggeredWebhook::STATUS_NOT_RUN,
          pact_publication_id: pact.id,
          verification: verification,
          webhook: db_webhook,
          webhook_uuid: db_webhook.uuid,
          trigger_uuid: trigger_uuid,
          trigger_type: trigger_type,
          consumer: pact.consumer,
          provider: pact.provider
        )
      end

      def update_triggered_webhook_status triggered_webhook, status
        triggered_webhook.update(status: status)
      end

      def create_execution triggered_webhook, webhook_execution_result
        # TriggeredWebhook may have been deleted since the webhook execution started
        if TriggeredWebhook.where(id: triggered_webhook.id).any?
          Execution.create(
            triggered_webhook: triggered_webhook,
            success: webhook_execution_result.success?,
            logs: webhook_execution_result.logs)
        else
          logger.info("Could not save webhook execution for triggered webhook with id #{triggered_webhook.id} as it has been delete from the database")
        end
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

      def delete_triggered_webhooks_by_webhook_uuid uuid
        triggered_webhook_ids = TriggeredWebhook.where(webhook: Webhook.where(uuid: uuid)).select_for_subquery(:id)
        Execution.where(triggered_webhook_id: triggered_webhook_ids).delete
        DeprecatedExecution.where(webhook_id: Webhook.where(uuid: uuid).select_for_subquery(:id)).delete
        TriggeredWebhook.where(id: triggered_webhook_ids).delete
      end

      def delete_triggered_webhooks_by_pact_publication_ids pact_publication_ids
        triggered_webhook_ids = TriggeredWebhook.where(pact_publication_id: pact_publication_ids).select_for_subquery(:id)
        Execution.where(triggered_webhook_id: triggered_webhook_ids).delete
        TriggeredWebhook.where(id: triggered_webhook_ids).delete
        DeprecatedExecution.where(pact_publication_id: pact_publication_ids).delete
      end

      def find_latest_triggered_webhooks_for_pact pact
        if pact
          find_latest_triggered_webhooks(pact.consumer, pact.provider)
        else
          []
        end
      end

      def find_latest_triggered_webhooks consumer, provider
        LatestTriggeredWebhook
          .where(consumer: consumer, provider: provider)
          .order(:id)
          .all
      end

      def find_triggered_webhooks_for_pact pact
        PactBroker::Webhooks::TriggeredWebhook
          .where(pact_publication_id: pact.pact_publication_id)
          .eager(:webhook)
          .eager(:webhook_executions)
          .reverse(:created_at, :id)
      end

      def find_triggered_webhooks_for_verification verification
        PactBroker::Webhooks::TriggeredWebhook
          .where(verification_id: verification.id)
          .eager(:webhook)
          .eager(:webhook_executions)
          .reverse(:created_at, :id)
      end

      def fail_retrying_triggered_webhooks
        TriggeredWebhook.retrying.update(status: TriggeredWebhook::STATUS_FAILURE)
      end
    end
  end
end
