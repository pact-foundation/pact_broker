require 'pact_broker/repositories'

module PactBroker

  module Services
    class WebhookService

      extend PactBroker::Repositories

      def self.create webhook, consumer, provider
        webhook_repository.create webhook, consumer, provider
      end
    end
  end
end