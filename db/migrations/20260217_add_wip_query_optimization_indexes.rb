require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  # Disable transaction wrapper so we can use CONCURRENTLY for PostgreSQL
  no_transaction if PactBroker::MigrationHelper.postgres?
  
  up do
    if PactBroker::MigrationHelper.postgres?
      alter_table(:pact_publications) do
        add_index([:provider_id, :created_at], name: "idx_pp_provider_created", concurrently: true)
      end
      
      alter_table(:verifications) do
        add_index([:provider_id, :provider_version_id, :success, :wip, :pact_version_id], name: "idx_verifications_provider_lookup", concurrently: true)
      end
    else
      alter_table(:pact_publications) do
        add_index([:provider_id, :created_at], name: "idx_pp_provider_created")
      end
      
      alter_table(:verifications) do
        add_index([:provider_id, :provider_version_id, :success, :wip, :pact_version_id], name: "idx_verifications_provider_lookup")
      end
    end
  end

  down do
    if PactBroker::MigrationHelper.postgres?
      alter_table(:pact_publications) do
        drop_index([:provider_id, :created_at], name: "idx_pp_provider_created", if_exists: true)
      end

      alter_table(:verifications) do
        drop_index([:provider_id, :provider_version_id, :success, :wip, :pact_version_id], name: "idx_verifications_provider_lookup", if_exists: true)
      end
    else
      # These indexes are safe to leave in place and don't change the test behaviour
    end
  end
end
