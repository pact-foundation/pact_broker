require "pact_broker/db/data_migrations/set_contract_data_updated_at_for_integrations"

Sequel.migration do
  up do
    PactBroker::DB::DataMigrations::SetContractDataUpdatedAtForIntegrations.call(self)
  end

  down do

  end
end
