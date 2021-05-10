Sequel.migration do
  up do
    alter_table(:deployed_versions) do
      add_column(:target, String)
      add_column(:target_for_index, String, default: "", null: false)
      set_column_allow_null(:replaced_previous_deployed_version)
      set_column_allow_null(:currently_deployed)
      drop_index [:pacticipant_id, :currently_deployed], name: "deployed_versions_pacticipant_id_currently_deployed_index"
    end
  end

  down do
    alter_table(:deployed_versions) do
      drop_column(:target)
      drop_column(:target_for_index)
      set_column_not_null(:replaced_previous_deployed_version)
      set_column_not_null(:currently_deployed)
      add_index [:pacticipant_id, :currently_deployed], name: "deployed_versions_pacticipant_id_currently_deployed_index"
    end
  end
end
