Sequel.migration do
  up do
    alter_table(:deployed_versions) do
      add_column(:target, String)
      add_column(:deployment_complete, TrueClass)
      set_column_allow_null(:replaced_previous_deployed_version)
      set_column_allow_null(:currently_deployed)
    end
  end

  down do
    alter_table(:deployed_versions) do
      drop_column(:target)
      drop_column(:deployment_complete)
    end
  end
end
