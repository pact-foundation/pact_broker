module PactBroker
  module Api
    module Resources
      module WebhookExecutionMethods
        def webhook_execution_configuration
          application_context.webhook_execution_configuration_creator.call(self)
        end
      end
    end
  end
end
