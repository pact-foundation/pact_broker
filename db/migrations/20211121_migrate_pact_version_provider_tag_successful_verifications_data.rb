
Sequel.migration do
  up do
    PactBroker::Db::DataMigrations::MigratePactVersionProviderTagSuccessfulVerifications.call(self)
  end

  down do

  end
end
