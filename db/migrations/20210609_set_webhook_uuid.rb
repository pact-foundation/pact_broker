
Sequel.migration do
  up do
    PactBroker::Db::DataMigrations::SetWebhookUuid.call(self)
  end

  down do

  end
end
