module PactBroker
  module Api
    module Resources
      module WebhookExecutionMethods
        def webhook_execution_configuration
          PactBroker::Webhooks::ExecutionConfiguration.new
            .with_show_response(PactBroker.configuration.show_webhook_response?)
            .with_webhook_context(base_url: base_url)
        end
      end
    end
  end
end
