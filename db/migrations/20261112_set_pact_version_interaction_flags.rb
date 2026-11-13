require "pact_broker/db/data_migrations/set_pact_version_interaction_flags"

Sequel.migration do
  # Each page of rows commits on its own, so a failed fill keeps its progress and a re-run resumes.
  no_transaction

  up do
    PactBroker::DB::DataMigrations::SetPactVersionInteractionFlags.call(self)
  end

  down do
    # The fill is not reverted, because the flags are derived from the pact content.
  end
end
