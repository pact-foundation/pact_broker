require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'pact_broker/webhooks/job'
require 'base64'
require 'securerandom'

module PactBroker

  module Webhooks
    class Service

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
        webhook_repository.unlink_executions_by_webhook_uuid uuid
        webhook_repository.delete_by_uuid uuid
      end

      def self.delete_by_pacticipant pacticipant
        webhook_repository.delete_by_pacticipant pacticipant
      end

      def self.find_all
        webhook_repository.find_all
      end

      def self.execute_webhook_now webhook, pact
        webhook_execution_result = webhook.execute
        webhook_repository.create_execution webhook, webhook_execution_result, pact
        webhook_execution_result
      end

      def self.find_by_consumer_and_provider consumer, provider
        webhook_repository.find_by_consumer_and_provider consumer, provider
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
        webhooks.each do | webhook |
          begin
            logger.info "Scheduling job for #{webhook.description} with uuid #{webhook.uuid}"
            Job.perform_async webhook: webhook, pact: pact
          rescue StandardError => e
            log_error e
          end
        end
      end

      def self.find_webhook_executions_after_current_pact_version_created pact
        webhook_repository.find_webhook_executions_after PactBroker::Pacts::PactVersion.find(sha: pact.pact_version_sha).created_at, pact.consumer.id, pact.provider.id
      end
    end
  end
end
