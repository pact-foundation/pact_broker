require "pact_broker/configuration"
require "pact_broker/webhooks/execution_configuration"

module PactBroker
  module Webhooks
    class ExecutionConfigurationCreator
      def self.call(resource)
        PactBroker::Webhooks::ExecutionConfiguration.new
          .with_show_response(PactBroker.configuration.show_webhook_response?)
          .with_retry_schedule(PactBroker.configuration.webhook_retry_schedule)
          .with_webhook_context(base_url: resource.base_url)
      end
    end
  end
end
