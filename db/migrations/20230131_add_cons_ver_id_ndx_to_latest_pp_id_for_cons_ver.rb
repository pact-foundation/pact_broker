require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  up do
    if !mysql?
      alter_table(:latest_pact_publication_ids_for_consumer_versions) do
        add_index([:consumer_version_id], name: "latest_pp_ids_for_cons_ver_con_ver_id_ndx")
      end
    end
  end

  down do
    if !mysql?
      alter_table(:latest_pact_publication_ids_for_consumer_versions) do
        drop_index([:consumer_version_id], name: "latest_pp_ids_for_cons_ver_con_ver_id_ndx")
      end
    end
  end
end
