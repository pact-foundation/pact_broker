require_relative 'migration_helper'

include PactBroker::MigrationHelper

Sequel.migration do
  change do
    alter_table(:tags) do
      add_column(:pacticipant_id, Integer)
      add_column(:version_order, Integer)
      add_index(:version_id, name: "ndx_tags_version_id")
      add_index(:pacticipant_id, name: "ndx_tags_pacticipant_id")
    end
  end
end
