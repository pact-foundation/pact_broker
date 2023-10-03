Sequel.migration do
  change do
    alter_table(:deployed_versions) do
      add_index(:version_id, name: "deployed_versions_version_id_ndx")
    end
  end
end
