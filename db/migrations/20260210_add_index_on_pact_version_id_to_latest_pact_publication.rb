require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  up do
    if !mysql?
      alter_table(:latest_pact_publication_ids_for_consumer_versions) do
        add_index :pact_version_id, name: :latest_pp_ids_for_cons_ver_pact_version_id_index
      end
    end
  end

  down do
    if !mysql?
      alter_table(:latest_pact_publication_ids_for_consumer_versions) do
        drop_index :pact_version_id, name: :latest_pp_ids_for_cons_ver_pact_version_id_index
      end
    end
  end
end

