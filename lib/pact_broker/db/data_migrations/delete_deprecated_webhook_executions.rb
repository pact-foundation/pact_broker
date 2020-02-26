require 'pact_broker/db/data_migrations/helpers'

module PactBroker
  module DB
    module DataMigrations
      class DeleteDeprecatedWebhookExecutions
        extend Helpers

        def self.call(connection)
          if columns_exist?(connection)
            connection[:webhook_executions].where(triggered_webhook_id: nil).delete
          end
        end

        def self.columns_exist?(connection)
          column_exists?(connection, :webhook_executions, :triggered_webhook_id)
        end
      end
    end
  end
end
