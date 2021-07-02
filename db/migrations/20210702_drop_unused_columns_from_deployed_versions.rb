Sequel.migration do
  up do
    alter_table(:deployed_versions) do
      drop_column(:replaced_previous_deployed_version)
      drop_column(:currently_deployed)
    end
  end

  down do
    alter_table(:deployed_versions) do
      add_column(:replaced_previous_deployed_version, TrueClass)
      add_column(:currently_deployed, TrueClass)
    end
  end
end
