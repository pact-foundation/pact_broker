require_relative 'migration_helper'

include PactBroker::MigrationHelper

Sequel.migration do
  up do
    if postgres?
      run("CREATE INDEX tags_pacticipant_id_name_version_order_index ON tags (pacticipant_id, name, version_order DESC);")
      run("CREATE INDEX versions_pacticipant_id_order_desc_index ON versions (pacticipant_id, order DESC);")
    else
      alter_table(:tags) do
        add_index([:pacticipant_id, :name, :version_order], name: "tags_pacticipant_id_name_version_order_index")
      end
    end
  end

  down do
    alter_table(:tags) do
      drop_index([:pacticipant_id, :name, :version_order], name: "tags_pacticipant_id_name_version_order_index")
    end

    if postgres?
      run("DROP INDEX versions_pacticipant_id_order_desc_index")
    end
  end
end
