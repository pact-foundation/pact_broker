require "pact_broker/db/data_migrations/set_webhook_uuid"

Sequel.migration do
  up do
    PactBroker::DB::DataMigrations::SetWebhookUuid.call(self)
  end

  down do

  end
end
