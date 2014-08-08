require 'pact_broker/repositories'
require 'pact_broker/logging'

module PactBroker

  module Services
    class WebhookService

      extend Repositories
      include Logging

      def self.create webhook, consumer, provider
        webhook_repository.create webhook, consumer, provider
      end

      def self.find_by_uuid uuid
        webhook_repository.find_by_uuid uuid
      end

      def self.delete_by_uuid uuid
        webhook_repository.delete_by_uuid uuid
      end

      def self.find_all
        webhook_repository.find_all
      end

      def self.execute_webhook pact
        webhook = webhook_repository.find_by_consumer_and_provider pact.consumer, pact.provider
        if webhook
          run_later(webhook)
        else
          logger.debug "No webhook found for consumer \"#{pact.consumer.name}\" and provider \"#{pact.provider.name}\""
        end
      end

      # TODO background job?
      def self.run_later webhook
        Thread.new do
          webhook.execute
        end
      end
    end
  end
end