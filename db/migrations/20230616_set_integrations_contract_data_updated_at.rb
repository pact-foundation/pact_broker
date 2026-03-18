
Sequel.migration do
  up do
    PactBroker::Db::DataMigrations::SetContractDataUpdatedAtForIntegrations.call(self)
  end

  down do

  end
end
