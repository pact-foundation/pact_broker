require "pact_broker/db/data_migrations/migrate_pact_version_provider_tag_successful_verifications"

Sequel.migration do
  up do
    PactBroker::DB::DataMigrations::MigratePactVersionProviderTagSuccessfulVerifications.call(self)
  end

  down do

  end
end
