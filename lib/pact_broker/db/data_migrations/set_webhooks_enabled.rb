require "pact_broker/db/data_migrations/helpers"

module PactBroker
  module DB
    module DataMigrations
      class SetWebhooksEnabled
        extend Helpers

        def self.call(connection)
          if column_exists?(connection, :webhooks, :enabled)
            connection[:webhooks].where(enabled: nil).update(enabled: true)
          end
        end
      end
    end
  end
end
