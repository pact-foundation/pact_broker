
Sequel.migration do
  up do
    PactBroker::Db::DataMigrations::MigrateWebhookHeaders.call(self)
  end

  down do
  end
end
