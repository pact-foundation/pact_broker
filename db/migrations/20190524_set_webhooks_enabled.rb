require 'pact_broker/db/data_migrations/set_webhooks_enabled'

Sequel.migration do
  up do
    PactBroker::DB::DataMigrations::SetWebhooksEnabled.call(self)
  end

  down do
  end
end
