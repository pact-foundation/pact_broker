require 'pact_broker/db/data_migrations/helpers'

module PactBroker
  module DB
    module DataMigrations
      class MigrateWebhookHeaders
        extend Helpers

        def self.call(connection)
          if columns_exist?(connection)
            connection[:webhook_headers].for_update.each do | webhook_header |
              webhook = connection[:webhooks].for_update.where(id: webhook_header[:webhook_id]).first
              new_headers = webhook[:headers] ? JSON.parse(webhook[:headers]) : {}
              new_headers[webhook_header[:name]] = webhook_header[:value]
              connection[:webhooks].where(id: webhook[:id]).update(headers: new_headers.to_json)
              connection[:webhook_headers].where(webhook_header).delete
            end
          end
        end

        def self.columns_exist?(connection)
          column_exists?(connection, :webhooks, :headers) &&
            column_exists?(connection, :webhook_headers, :name) &&
            column_exists?(connection, :webhook_headers, :value) &&
            column_exists?(connection, :webhook_headers, :webhook_id)
        end
      end
    end
  end
end
