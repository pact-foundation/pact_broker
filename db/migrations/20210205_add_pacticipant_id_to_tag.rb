require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  change do
    alter_table(:tags) do
      # TODO set_column_not_null(:pacticipant_id)
      # TODO set_column_not_null(:version_order)
      add_column(:pacticipant_id, Integer)
      add_column(:version_order, Integer)
      add_index(:version_order, name: "tags_version_order_index")
      add_index(:version_id, name: "tags_version_id_index")
      add_index(:pacticipant_id, name: "tags_pacticipant_id_index")
    end
  end
end
