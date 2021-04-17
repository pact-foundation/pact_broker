Sequel.migration do
  up do
    alter_table(:deployed_versions) do
      add_column(:target, String)
      set_column_allow_null(:replaced_previous_deployed_version)
      set_column_allow_null(:currently_deployed)
    end
  end

  down do
    alter_table(:deployed_versions) do
      drop_column(:target)
    end
  end
end
