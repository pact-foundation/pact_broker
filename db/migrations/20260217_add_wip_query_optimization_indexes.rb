require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  no_transaction if PactBroker::MigrationHelper.postgres?

  up do
    if !mysql?
      alter_table(:pact_publications) do
        add_index([:provider_id, :created_at], name: "idx_pp_provider_created", concurrently: postgres?)
      end

      alter_table(:verifications) do
        add_index([:provider_id, :provider_version_id, :success, :wip, :pact_version_id], name: "idx_verifications_provider_lookup", concurrently: postgres?)
      end
    end
  end

  down do
    if !mysql?
      alter_table(:pact_publications) do
        drop_index([:provider_id, :created_at], name: "idx_pp_provider_created")
      end

      alter_table(:verifications) do
        drop_index([:provider_id, :provider_version_id, :success, :wip, :pact_version_id], name: "idx_verifications_provider_lookup")
      end
    end
  end
end
