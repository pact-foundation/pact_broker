require_relative 'migration_helper'

Sequel.migration do
  up do
    alter_table(:tags) do
      add_foreign_key(:pacticipant_id, :pacticipants, foreign_key_constraint_name: 'fk_tag_pacticipant')
      add_column(:version_order, Integer)

      if PactBroker::MigrationHelper.postgres?
        add_index(:version_id, type: "hash", name: "ndx_tags_version_id")
        add_index(:pacticipant_id, type: "hash", name: "ndx_tags_pacticipant_id")
      else
        add_index(:version_id, name: "ndx_tags_version_id")
        add_index(:pacticipant_id, name: "ndx_tags_pacticipant_id")
        add_index([:pacticipant_id, :version_order], name: "ndx_tag_pacticipant_id_version_order")
      end
    end

    if PactBroker::MigrationHelper.postgres?
      # There doesn't seem to be a Sequel API for creating indexes with options
      run("CREATE INDEX ndx_tag_pacticipant_id_version_order ON tags (pacticipant_id DESC NULLS LAST, version_order DESC NULLS LAST);")
    end
  end

  down do
    alter_table(:tags) do
      drop_index(:version_id, name: "ndx_tags_pacticipant_id")
      drop_index(:version_id, name: "ndx_tags_version_id")
      drop_index([:pacticipant_id, :version_order], name: "ndx_tag_pacticipant_id_version_order")
      drop_foreign_key(:pacticipant_id, foreign_key_constraint_name: 'fk_tag_pacticipant')
      drop_column(:version_order)
    end
  end
end
