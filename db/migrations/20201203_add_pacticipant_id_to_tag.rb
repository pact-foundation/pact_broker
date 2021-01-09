require_relative 'migration_helper'

include PactBroker::MigrationHelper

Sequel.migration do
  up do
    alter_table(:tags) do
      add_column(:pacticipant_id, Integer)
      add_column(:version_order, Integer)
      add_index(:version_id, with_type_hash_if_postgres(name: "ndx_tags_version_id"))
      add_index(:pacticipant_id, with_type_hash_if_postgres(name: "ndx_tags_pacticipant_id"))
      add_index(:name, with_type_hash_if_postgres(name: "ndx_tags_tag_name")) # original index was a btree, not a hash
      drop_index([:name], name: 'ndx_tag_name')
    end

    if PactBroker::MigrationHelper.postgres?
      # There doesn't seem to be a Sequel API for creating indexes with options
      # Need to double check this
      run("CREATE INDEX ndx_tag_pacticipant_id_version_order ON tags (pacticipant_id DESC NULLS LAST, version_order DESC NULLS LAST);")
    end
  end

  down do
    alter_table(:tags) do
      drop_index(:name, name: "ndx_tags_tag_name")
      drop_index(:version_id, name: "ndx_tags_pacticipant_id")
      drop_index(:version_id, name: "ndx_tags_version_id")
      if PactBroker::MigrationHelper.postgres?
        drop_index([:pacticipant_id, :version_order], name: "ndx_tag_pacticipant_id_version_order")
      end
      drop_column(:pacticipant_id)
      drop_column(:version_order)

      add_index([:name], name: 'ndx_tag_name')
    end
  end
end
