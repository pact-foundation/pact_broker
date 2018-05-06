require 'pact_broker/db/data_migrations/20180501'

Sequel.migration do
  up do
    PactBroker::DB::DataMigrations::Migration20180501.call(self)
  end

  down do

  end
end
