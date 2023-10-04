require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  change do
    if !mysql?
      alter_table(:released_versions) do
        add_index(:version_id, name: "released_versions_version_id_ndx")
      end
    end
  end
end
