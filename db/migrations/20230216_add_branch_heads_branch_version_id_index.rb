require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  up do
    if !mysql?
      alter_table(:branch_heads) do
        add_index([:branch_version_id], name: "branch_heads_branch_version_id_index")
      end
    end
  end

  down do
    if !mysql?
      alter_table(:branch_heads) do
        drop_index([:branch_version_id], name: "branch_heads_branch_version_id_index")
      end
    end
  end
end
