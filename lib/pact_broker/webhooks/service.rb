require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'pact_broker/webhooks/job'
require 'base64'
require 'securerandom'
require 'pact_broker/webhooks/triggered_webhook'
require 'pact_broker/webhooks/status'

module PactBroker

  module Webhooks
    class Service

      PUBLICATION = PactBroker::Webhooks::TriggeredWebhook::TRIGGER_TYPE_PUBLICATION
      USER = PactBroker::Webhooks::TriggeredWebhook::TRIGGER_TYPE_USER

      extend Repositories
      include Logging

      def self.next_uuid
        SecureRandom.urlsafe_base64
      end

      def self.errors webhook
        contract = PactBroker::Api::Contracts::WebhookContract.new(webhook)
        contract.validate(webhook.attributes)
        contract.errors
      end

      def self.create uuid, webhook, consumer, provider
        webhook_repository.create uuid, webhook, consumer, provider
      end

      def self.find_by_uuid uuid
        webhook_repository.find_by_uuid uuid
      end

      def self.delete_by_uuid uuid
        webhook_repository.unlink_triggered_webhooks_by_webhook_uuid uuid
        webhook_repository.delete_by_uuid uuid
      end

      def self.delete_all_webhhook_related_objects_by_pacticipant pacticipant
        webhook_repository.delete_executions_by_pacticipant pacticipant
        webhook_repository.delete_triggered_webhooks_by_pacticipant pacticipant
        webhook_repository.delete_by_pacticipant pacticipant
      end

      def self.find_all
        webhook_repository.find_all
      end

      def self.execute_webhook_now webhook, pact
        triggered_webhook = webhook_repository.create_triggered_webhook(next_uuid, webhook, pact, USER)
        webhook_execution_result = execute_triggered_webhook_now triggered_webhook
        if webhook_execution_result.success?
          webhook_repository.update_triggered_webhook_status triggered_webhook, TriggeredWebhook::STATUS_SUCCESS
        else
          webhook_repository.update_triggered_webhook_status triggered_webhook, TriggeredWebhook::STATUS_FAILURE
        end
      end

      def self.execute_triggered_webhook_now triggered_webhook
        webhook_execution_result = triggered_webhook.execute
        webhook_repository.create_execution triggered_webhook, webhook_execution_result
        webhook_execution_result
      end

      def self.update_triggered_webhook_status triggered_webhook, status
        webhook_repository.update_triggered_webhook_status triggered_webhook, status
      end

      def self.find_by_consumer_and_provider consumer, provider
        webhook_repository.find_by_consumer_and_provider consumer, provider
      end

      def self.status_for consumer, provider
        pact = pact_service.find_latest_pact consumer_name: consumer.name, provider_name: provider.name
        webhooks = find_by_consumer_and_provider pact.consumer, pact.provider
        webhook_executions = find_webhook_executions_after_current_pact_version_created(pact)
        PactBroker::Webhooks::Status.new(webhooks, webhook_executions)
      end

      def self.execute_webhooks pact
        webhooks = webhook_repository.find_by_consumer_and_provider pact.consumer, pact.provider

        if webhooks.any?
          run_later(webhooks, pact)
        else
          logger.debug "No webhook found for consumer \"#{pact.consumer.name}\" and provider \"#{pact.provider.name}\""
        end
      end

      def self.run_later webhooks, pact
        trigger_uuid = next_uuid
        webhooks.each do | webhook |
          begin
            triggered_webhook = webhook_repository.create_triggered_webhook(trigger_uuid, webhook, pact, PUBLICATION)
            logger.info "Scheduling job for #{webhook.description} with uuid #{webhook.uuid}"
            Job.perform_async triggered_webhook: triggered_webhook
          rescue StandardError => e
            log_error e
          end
        end
      end

      def self.find_webhook_executions_after_current_pact_version_created pact
        webhook_repository.find_webhook_executions_after PactBroker::Pacts::PactVersion.find(sha: pact.pact_version_sha).created_at, pact.consumer.id, pact.provider.id
      end

      def self.find_latest_triggered_webhooks consumer, provider
        webhook_repository.find_latest_triggered_webhooks consumer, provider
      end
    end
  end
end
