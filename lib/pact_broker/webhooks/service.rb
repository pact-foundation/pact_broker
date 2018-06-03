require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'base64'
require 'securerandom'
require 'pact_broker/webhooks/job'
require 'pact_broker/webhooks/triggered_webhook'
require 'pact_broker/webhooks/status'
require 'pact_broker/webhooks/webhook_event'

module PactBroker

  module Webhooks
    class Service

      RESOURCE_CREATION = PactBroker::Webhooks::TriggeredWebhook::TRIGGER_TYPE_RESOURCE_CREATION
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

      def self.update_by_uuid uuid, webhook
        webhook_repository.update_by_uuid uuid, webhook
      end

      def self.delete_by_uuid uuid
        webhook_repository.delete_triggered_webhooks_by_webhook_uuid uuid
        webhook_repository.delete_by_uuid uuid
      end

      def self.delete_all_webhhook_related_objects_by_pacticipant pacticipant
        webhook_repository.delete_executions_by_pacticipant pacticipant
        webhook_repository.delete_triggered_webhooks_by_pacticipant pacticipant
        webhook_repository.delete_by_pacticipant pacticipant
      end

      def self.delete_all_webhook_related_objects_by_pact_publication_ids pact_publication_ids
        webhook_repository.delete_triggered_webhooks_by_pact_publication_ids pact_publication_ids
      end

      def self.find_all
        webhook_repository.find_all
      end

      def self.execute_webhook_now webhook, pact
        triggered_webhook = webhook_repository.create_triggered_webhook(next_uuid, webhook, pact, USER)
        options = { failure_log_message: "Webhook execution failed", show_response: PactBroker.configuration.show_webhook_response?}
        webhook_execution_result = execute_triggered_webhook_now triggered_webhook, options
        if webhook_execution_result.success?
          webhook_repository.update_triggered_webhook_status triggered_webhook, TriggeredWebhook::STATUS_SUCCESS
        else
          webhook_repository.update_triggered_webhook_status triggered_webhook, TriggeredWebhook::STATUS_FAILURE
        end
        webhook_execution_result
      end

      def self.execute_triggered_webhook_now triggered_webhook, options
        webhook_execution_result = triggered_webhook.execute options
        webhook_repository.create_execution triggered_webhook, webhook_execution_result
        webhook_execution_result
      end

      def self.update_triggered_webhook_status triggered_webhook, status
        webhook_repository.update_triggered_webhook_status triggered_webhook, status
      end

      def self.find_by_consumer_and_provider consumer, provider
        webhook_repository.find_by_consumer_and_provider consumer, provider
      end

      def self.execute_webhooks pact, event_name
        webhooks = webhook_repository.find_by_consumer_and_provider_and_event_name pact.consumer, pact.provider, event_name

        if webhooks.any?
          run_later(webhooks, pact, event_name)
        else
          logger.debug "No webhook found for consumer \"#{pact.consumer.name}\" and provider \"#{pact.provider.name}\""
        end
      end

      def self.run_later webhooks, pact, event_name
        trigger_uuid = next_uuid
        webhooks.each do | webhook |
          begin
            triggered_webhook = webhook_repository.create_triggered_webhook(trigger_uuid, webhook, pact, RESOURCE_CREATION)
            logger.info "Scheduling job for #{webhook.description} with uuid #{webhook.uuid}"
            # Bit of a dodgey hack to make sure the request transaction has finished before we execute the webhook
            Job.perform_in(5, triggered_webhook: triggered_webhook)
          rescue StandardError => e
            log_error e
          end
        end
      end

      def self.find_latest_triggered_webhooks consumer, provider
        webhook_repository.find_latest_triggered_webhooks consumer, provider
      end

      def self.fail_retrying_triggered_webhooks
        webhook_repository.fail_retrying_triggered_webhooks
      end
    end
  end
end
