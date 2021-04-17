module PactBroker
  module Api
    module Resources
      module WebhookExecutionMethods
        def webhook_execution_configuration
          application_context.webhook_execution_configuration_creator.call(self)
        end

        def webhook_options
          {
            database_connector: database_connector,
            webhook_execution_configuration: webhook_execution_configuration
          }
        end
      end
    end
  end
end
