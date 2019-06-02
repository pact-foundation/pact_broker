require 'pact_broker/db/data_migrations/set_latest_version_sequence_value'

Sequel.migration do
  up do
    PactBroker::DB::DataMigrations::SetLatestVersionSequenceValue.call(self)
  end

  down do
  end
end
