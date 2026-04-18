
Sequel.migration do
  up do
    PactBroker::Db::DataMigrations::SetWebhooksEnabled.call(self)
  end

  down do
  end
end
