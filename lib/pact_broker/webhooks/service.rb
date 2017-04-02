require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'base64'

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
        webhook_repository.delete_by_uuid uuid
      end

      def self.delete_by_pacticipant pacticipant
        webhook_repository.delete_by_pacticipant pacticipant
      end

      def self.find_all
        webhook_repository.find_all
      end

      def self.execute_webhook_now webhook
        webhook.execute
      end

      def self.find_by_consumer_and_provider consumer, provider
        webhook_repository.find_by_consumer_and_provider consumer, provider
      end

      def self.execute_webhooks pact
        webhooks = webhook_repository.find_by_consumer_and_provider pact.consumer, pact.provider
        if webhooks.any?
          run_later(webhooks)
        else
          logger.debug "No webhook found for consumer \"#{pact.consumer.name}\" and provider \"#{pact.provider.name}\""
        end
      end

      # TODO background job?
      def self.run_later webhooks
        Thread.new do
          webhooks.each do | webhook |
            begin
              webhook.execute
            rescue StandardError => e
              # Exceptions are already logged, no need to log again.
            end
          end
        end
      end
    end
  end
end
