require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  # Disable transaction wrapper so we can use CONCURRENTLY for PostgreSQL
  no_transaction if postgres?
  
  up do
    alter_table(:pact_publications) do
      add_index([:provider_id, :created_at], name: "idx_pp_provider_created", concurrently: postgres?)
    end
    
    alter_table(:verifications) do
      add_index([:provider_id, :provider_version_id, :success, :wip, :pact_version_id], name: "idx_verifications_provider_lookup", concurrently: postgres?)
    end
  end

  down do
    alter_table(:pact_publications) do
      drop_index([:provider_id, :created_at], name: "idx_pp_provider_created", if_exists: true)
    end

    alter_table(:verifications) do
      drop_index([:provider_id, :provider_version_id, :success, :wip, :pact_version_id], name: "idx_verifications_provider_lookup", if_exists: true)
    end
  end
end
