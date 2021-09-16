require "sequel"
require "pact_broker/domain/webhook"
require "pact_broker/domain/pacticipant"
require "pact_broker/db"
require "pact_broker/webhooks/webhook"
require "pact_broker/webhooks/webhook_event"
require "pact_broker/webhooks/triggered_webhook"
require "pact_broker/webhooks/latest_triggered_webhook"
require "pact_broker/webhooks/execution"
require "pact_broker/logging"

module PactBroker
  module Webhooks
    class Repository
      include PactBroker::Logging

      include Repositories

      def create uuid, webhook, consumer, provider
        consumer = find_pacticipant_by_name(webhook.consumer) || consumer
        provider = find_pacticipant_by_name(webhook.provider) || provider
        db_webhook = Webhook.from_domain webhook, consumer, provider
        db_webhook.uuid = uuid
        db_webhook.save
        (webhook.events || []).each do | webhook_event |
          db_webhook.add_event(webhook_event)
        end
        find_by_uuid db_webhook.uuid
      end

      # policy applied at resource level
      def find_by_uuid uuid
        deliberately_unscoped(Webhook).where(uuid: uuid).limit(1).collect(&:to_domain)[0]
      end

      # policy applied at resource level
      def update_by_uuid uuid, webhook
        existing_webhook = deliberately_unscoped(Webhook).find(uuid: uuid)
        existing_webhook.consumer_id = find_pacticipant_by_name(webhook.consumer)&.id
        existing_webhook.provider_id = find_pacticipant_by_name(webhook.provider)&.id
        existing_webhook.update_from_domain(webhook).save
        existing_webhook.events.collect(&:delete)
        (webhook.events || []).each do | webhook_event |
          existing_webhook.add_event(webhook_event)
        end
        find_by_uuid uuid
      end

      # policy applied at resource level
      def delete_by_uuid uuid
        deliberately_unscoped(Webhook).where(uuid: uuid).destroy
      end

      # policy applied at resource level for pacticipant
      # If we're deleting the pacticipant, then we actually do want to delete the triggered webhooks
      def delete_by_pacticipant pacticipant
        deliberately_unscoped(TriggeredWebhook).where(consumer_id: pacticipant.id).delete
        deliberately_unscoped(TriggeredWebhook).where(provider_id: pacticipant.id).delete
        deliberately_unscoped(TriggeredWebhook).where(webhook: deliberately_unscoped(Webhook).where(consumer_id: pacticipant.id)).delete
        deliberately_unscoped(TriggeredWebhook).where(webhook: deliberately_unscoped(Webhook).where(provider_id: pacticipant.id)).delete
        deliberately_unscoped(Webhook).where(consumer_id: pacticipant.id).delete
        deliberately_unscoped(Webhook).where(provider_id: pacticipant.id).delete
      end

      # this needs the scope!
      def find_all
        scope_for(Webhook).all.collect(&:to_domain)
      end

      # needs to know if there are any at all, regardless of whether or not user can edit them
      def any_webhooks_configured_for_pact?(pact)
        deliberately_unscoped(Webhook).find_by_consumer_and_or_provider(pact.consumer, pact.provider).any?
      end

      def find_by_consumer_and_provider consumer, provider
        scope_for(Webhook).find_by_consumer_and_provider(consumer, provider).collect(&:to_domain)
      end

      # deleting a particular integration
      # do delete triggered webhooks
      # only delete stuff matching both, as other integrations may still be present
      def delete_by_consumer_and_provider consumer, provider
        webhooks_to_delete = deliberately_unscoped(Webhook).where(consumer: consumer, provider: provider)
        TriggeredWebhook.where(webhook: webhooks_to_delete).delete
        # Delete the orphaned triggerred webhooks
        TriggeredWebhook.where(consumer: consumer, provider: provider).delete
        webhooks_to_delete.delete
      end

      def find_webhooks_to_trigger consumer: , provider: , event_name:
        deliberately_unscoped(Webhook)
          .select_all_qualified
          .enabled
          .for_event_name(event_name)
          .find_by_consumer_and_or_provider(consumer, provider)
          .collect(&:to_domain)
      end

      # rubocop: disable Metrics/ParameterLists
      def create_triggered_webhook uuid, webhook, pact, verification, trigger_type, event_name, event_context
        db_webhook = deliberately_unscoped(Webhook).where(uuid: webhook.uuid).single_record
        # trigger_uuid was meant to be one per *event*, not one per triggered webhook, but its intent got lost over time.
        # Retiring it now in favour of uuid, but can't leave it empty because
        # it has a not-null and unique webhook_uuid/trigger_uuid constraint on it.
        TriggeredWebhook.create(
          uuid: uuid,
          status: TriggeredWebhook::STATUS_NOT_RUN,
          pact_publication_id: pact.id,
          verification: verification,
          webhook: db_webhook,
          webhook_uuid: db_webhook.uuid,
          trigger_uuid: uuid,
          trigger_type: trigger_type,
          consumer: pact.consumer,
          provider: pact.provider,
          event_name: event_name,
          event_context: event_context
        )
      end
      # rubocop: enable Metrics/ParameterLists

      def update_triggered_webhook_status triggered_webhook, status
        triggered_webhook.update(status: status)
      end

      def create_execution triggered_webhook, webhook_execution_result
        # TriggeredWebhook may have been deleted since the webhook execution started
        if deliberately_unscoped(TriggeredWebhook).where(id: triggered_webhook.id).any?
          Execution.create(
            triggered_webhook: triggered_webhook,
            success: webhook_execution_result.success?,
            logs: webhook_execution_result.logs)
        else
          logger.info("Could not save webhook execution for triggered webhook with id #{triggered_webhook.id} as it has been delete from the database")
        end
      end

      def delete_triggered_webhooks_by_version_id version_id
        delete_triggered_webhooks_by_pact_publication_ids(PactBroker::Pacts::PactPublication.where(consumer_version_id: version_id).select_for_subquery(:id))
        delete_triggered_webhooks_by_verification_ids(PactBroker::Domain::Verification.where(provider_version_id: version_id).select_for_subquery(:id))
      end

      def delete_triggered_webhooks_by_verification_ids verification_ids
        delete_triggered_webhooks_and_executions(TriggeredWebhook.where(verification_id: verification_ids).select_for_subquery(:id))
      end

      def delete_triggered_webhooks_by_pact_publication_ids pact_publication_ids
        triggered_webhook_ids = TriggeredWebhook.where(pact_publication_id: pact_publication_ids).select_for_subquery(:id)
        delete_triggered_webhooks_and_executions(triggered_webhook_ids)
      end

      def find_latest_triggered_webhooks_for_pact pact
        if pact
          find_latest_triggered_webhooks(pact.consumer, pact.provider)
        else
          []
        end
      end

      def find_latest_triggered_webhooks consumer, provider
        # policy already applied to pact
        deliberately_unscoped(LatestTriggeredWebhook)
          .where(consumer: consumer, provider: provider)
          .order(:id)
          .all
      end

      def find_triggered_webhooks_for_pact pact
        scope_for(PactBroker::Webhooks::TriggeredWebhook)
          .where(pact_publication_id: pact.pact_publication_id)
          .eager(:webhook)
          .eager(:webhook_executions)
          .reverse(:created_at, :id)
      end

      def find_triggered_webhooks_for_verification verification
        scope_for(PactBroker::Webhooks::TriggeredWebhook)
          .where(verification_id: verification.id)
          .eager(:webhook)
          .eager(:webhook_executions)
          .reverse(:created_at, :id)
      end

      def fail_retrying_triggered_webhooks
        deliberately_unscoped(TriggeredWebhook).retrying.update(status: TriggeredWebhook::STATUS_FAILURE)
      end

      private

      def find_pacticipant_by_name(pacticipant)
        return unless pacticipant&.name

        pacticipant_repository.find_by_name(pacticipant.name)
      end

      def deliberately_unscoped(scope)
        scope
      end

      def scope_for(scope)
        if @no_policy
          scope
        else
          PactBroker.policy_scope!(scope)
        end
      end

      def delete_triggered_webhooks_and_executions triggered_webhook_ids
        Execution.where(triggered_webhook_id: triggered_webhook_ids).delete
        TriggeredWebhook.where(id: triggered_webhook_ids).delete
      end
    end
  end
end
