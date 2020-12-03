require_relative 'migration_helper'

Sequel.migration do
  up do
    alter_table(:tags) do
      add_foreign_key(:pacticipant_id, :pacticipants, foreign_key_constraint_name: 'fk_tag_pacticipant')
      add_column(:version_order, Integer)

      if PactBroker::MigrationHelper.postgres?
        add_index(:version_id, type: "hash", name: "ndx_tags_version_id")
        run("CREATE INDEX ndx_tag_pacticipant_id_version_order ON tags (pacticipant_id DESC NULLS LAST, version_order DESC NULLS LAST);")
      else
        add_index(:version_id, name: "ndx_tags_version_id")
        add_index([:pacticipant_id, :version_order], name: "ndx_tag_pacticipant_id_version_order")
      end
    end
  end

  down do
    alter_table(:tags) do
      if PactBroker::MigrationHelper.postgres?
        drop_index(:version_id, name: "ndx_tags_version_id")
        run("DROP INDEX ndx_tag_pacticipant_id_version_order")
      else
        drop_index(:version_id, name: "ndx_tags_version_id")
        drop_index([:pacticipant_id, :version_order], name: "ndx_tag_pacticipant_id_version_order")
      end
      drop_foreign_key(:pacticipant_id, foreign_key_constraint_name: 'fk_tag_pacticipant')
      drop_column(:version_order)
    end
  end
end
