require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'pact_broker/api/pact_broker_urls'
require 'base64'

module PactBroker

  module Services
    class WebhookService

      extend Repositories
      include Logging
      extend PactBroker::Api::PactBrokerUrls

      def self.next_uuid
        SecureRandom.urlsafe_base64
      end

      def self.errors webhook
        contract = PactBroker::Api::Contracts::WebhookContract.new(webhook)
        contract.validate
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

      def self.execute_webhook_now webhook, base_url
        webhook.execute latest_pact_version_url_for_webhook(webhook, base_url)
      end

      def self.find_by_consumer_and_provider consumer, provider
        webhook_repository.find_by_consumer_and_provider consumer, provider
      end

      def self.execute_webhooks pact, pact_version_url
        webhooks = webhook_repository.find_by_consumer_and_provider pact.consumer, pact.provider
        if webhooks.any?
          run_later(webhooks, pact_version_url)
        else
          logger.debug "No webhook found for consumer \"#{pact.consumer.name}\" and provider \"#{pact.provider.name}\""
        end
      end

      # TODO background job?
      def self.run_later webhooks, pact_version_url
        Thread.new do
          webhooks.each do | webhook |
            begin
              webhook.execute pact_version_url
            rescue StandardError => e
              # Exceptions are already logged, no need to log again.
            end
          end
        end
      end

      private

      def self.latest_pact_version_url_for_webhook webhook, base_url
        pact = pact_repository.find_latest_pact webhook.consumer.name, webhook.provider.name
        consumer_version_number = pact ? pact.consumer_version_number : '0'
      pact_version_url = pact_url_from_params(base_url, {provider_name: webhook.provider.name, consumer_name: webhook.consumer.name, consumer_version_number: consumer_version_number})
      end
    end
  end
end