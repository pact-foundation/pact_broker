require 'pact_broker/repositories'
require 'pact_broker/services'
require 'pact_broker/logging'
require 'base64'
require 'securerandom'
require 'pact_broker/webhooks/job'
require 'pact_broker/webhooks/triggered_webhook'
require 'pact_broker/webhooks/status'
require 'pact_broker/webhooks/webhook_event'
require 'pact_broker/verifications/placeholder_verification'
require 'pact_broker/pacts/placeholder_pact'
require 'pact_broker/api/decorators/webhook_decorator'

module PactBroker

  module Webhooks
    class Service

      RESOURCE_CREATION = PactBroker::Webhooks::TriggeredWebhook::TRIGGER_TYPE_RESOURCE_CREATION
      USER = PactBroker::Webhooks::TriggeredWebhook::TRIGGER_TYPE_USER

      extend Repositories
      extend Services
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

      def self.update_by_uuid uuid, params
        webhook = webhook_repository.find_by_uuid(uuid)
        # Dirty hack to maintain existing password if it is not submitted
        # This is required because the password is not returned in the API response
        # for security purposes, so it needs to be re-entered with every response.
        # TODO implement proper 'secrets' management.
        if webhook.request.password && !params['request'].key?('password')
          params['request']['password'] = webhook.request.password
        end
        PactBroker::Api::Decorators::WebhookDecorator.new(webhook).from_hash(params)
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

      def self.test_execution webhook
        options = { failure_log_message: "Webhook execution failed", show_response: PactBroker.configuration.show_webhook_response?, base_url: base_url}
        verification = nil
        if webhook.trigger_on_provider_verification_published?
          verification = verification_service.search_for_latest(webhook.consumer_name, webhook.provider_name) || PactBroker::Verifications::PlaceholderVerification.new
        end

        pact = pact_service.search_for_latest_pact(consumer_name: webhook.consumer_name, provider_name: webhook.provider_name) || PactBroker::Pacts::PlaceholderPact.new
        webhook.execute(pact, verification, options)
      end

      def self.execute_webhook_now webhook, pact, verification = nil
        triggered_webhook = webhook_repository.create_triggered_webhook(next_uuid, webhook, pact, verification, USER)
        options = { failure_log_message: "Webhook execution failed"}
        webhook_execution_result = execute_triggered_webhook_now triggered_webhook, options
        if webhook_execution_result.success?
          webhook_repository.update_triggered_webhook_status triggered_webhook, TriggeredWebhook::STATUS_SUCCESS
        else
          webhook_repository.update_triggered_webhook_status triggered_webhook, TriggeredWebhook::STATUS_FAILURE
        end
        webhook_execution_result
      end

      def self.execute_triggered_webhook_now triggered_webhook, options
        webhook_execution_result = triggered_webhook.execute options.merge(show_response: PactBroker.configuration.show_webhook_response?)
        webhook_repository.create_execution triggered_webhook, webhook_execution_result
        webhook_execution_result
      end

      def self.update_triggered_webhook_status triggered_webhook, status
        webhook_repository.update_triggered_webhook_status triggered_webhook, status
      end

      def self.find_for_pact pact
        webhook_repository.find_for_pact(pact)
      end

      def self.find_by_consumer_and_or_provider consumer, provider
        webhook_repository.find_by_consumer_and_or_provider(consumer, provider)
      end

      def self.find_by_consumer_and_provider consumer, provider
        webhook_repository.find_by_consumer_and_provider consumer, provider
      end

      def self.trigger_webhooks pact, verification, event_name
        webhooks = webhook_repository.find_by_consumer_and_or_provider_and_event_name pact.consumer, pact.provider, event_name

        if webhooks.any?
          run_later(webhooks, pact, verification, event_name)
        else
          logger.debug "No enabled webhooks found for consumer \"#{pact.consumer.name}\" and provider \"#{pact.provider.name}\" and event #{event_name}"
        end
      end

      def self.run_later webhooks, pact, verification, event_name
        trigger_uuid = next_uuid
        webhooks.each do | webhook |
          begin
            triggered_webhook = webhook_repository.create_triggered_webhook(trigger_uuid, webhook, pact, verification, RESOURCE_CREATION)
            logger.info "Scheduling job for #{webhook.description} with uuid #{webhook.uuid}"
            job_data = {
              triggered_webhook: triggered_webhook,
              database_connector: job_database_connector,
              base_url: base_url
            }
            # Delay slightly to make sure the request transaction has finished before we execute the webhook
            Job.perform_in(5, job_data)
          rescue StandardError => e
            log_error e
          end
        end
      end

      def self.job_database_connector
        Thread.current[:pact_broker_thread_data].database_connector
      end

      def self.base_url
        Thread.current[:pact_broker_thread_data].base_url
      end

      def self.find_latest_triggered_webhooks_for_pact pact
        webhook_repository.find_latest_triggered_webhooks_for_pact pact
      end

      def self.find_latest_triggered_webhooks consumer, provider
        webhook_repository.find_latest_triggered_webhooks consumer, provider
      end

      def self.fail_retrying_triggered_webhooks
        webhook_repository.fail_retrying_triggered_webhooks
      end

      def self.find_triggered_webhooks_for_pact pact
        webhook_repository.find_triggered_webhooks_for_pact(pact)
      end

      def self.find_triggered_webhooks_for_verification verification
        webhook_repository.find_triggered_webhooks_for_verification(verification)
      end
    end
  end
end
