
Sequel.migration do
  up do
    PactBroker::Db::DataMigrations::SetLatestVersionSequenceValue.call(self)
  end

  down do
  end
end
