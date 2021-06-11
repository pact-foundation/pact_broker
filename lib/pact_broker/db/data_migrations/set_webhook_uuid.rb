require "pact_broker/db/data_migrations/helpers"
require "sequel/extensions/core_refinements"
require "securerandom"

module PactBroker
  module DB
    module DataMigrations
      class SetWebhookUuid
        using Sequel::CoreRefinements
        extend Helpers

        def self.call(connection, _options = {})
          if required_columns_exist?(connection)
            connection[:triggered_webhooks].where(uuid: nil).update(uuid: [SecureRandom.uuid, "-", :id].sql_string_join)
          end
        end

        def self.required_columns_exist?(connection)
          columns_exist?(connection, :triggered_webhooks, [:uuid])
        end
      end
    end
  end
end
