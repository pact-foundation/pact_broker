require "pact_broker/db/data_migrations/migrate_webhook_headers"

Sequel.migration do
  up do
    PactBroker::DB::DataMigrations::MigrateWebhookHeaders.call(self)
  end

  down do
  end
end
