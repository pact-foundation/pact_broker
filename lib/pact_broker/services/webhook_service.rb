require 'pact_broker/repositories'

module PactBroker

  module Services
    class WebhookService

      extend PactBroker::Repositories

      def self.create webhook, consumer, provider
        webhook_repository.create webhook, consumer, provider
      end

      def self.find_by_uuid uuid
        webhook_repository.find_by_uuid uuid
      end

      def self.delete_by_uuid uuid
        webhook_repository.delete_by_uuid uuid
      end
    end
  end
end