require "pact_broker/db/data_migrations/set_pact_version_interaction_flags"

# Fills the rows that are still NULL, then forbids NULL.
Sequel.migration do
  up do
    PactBroker::DB::DataMigrations::SetPactVersionInteractionFlags.call(self)

    alter_table(:pact_versions) do
      set_column_not_null(:has_http_interactions)
    end
  end

  down do
    alter_table(:pact_versions) do
      set_column_allow_null(:has_http_interactions)
    end
  end
end
