require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  up do
    if !mysql?
      alter_table(:branch_versions) do
        add_index([:version_id, :branch_name], name: "branch_versions_version_id_branch_name_idx")
      end
    end
  end

  down do
    if !mysql?
      alter_table(:branch_versions) do
        drop_index([:version_id, :branch_name], name: "branch_versions_version_id_branch_name_idx")
      end
    end
  end
end
