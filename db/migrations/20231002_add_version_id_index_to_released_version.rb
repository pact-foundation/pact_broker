Sequel.migration do
  change do
    alter_table(:released_versions) do
      add_index(:version_id, name: "released_versions_version_id_ndx")
    end
  end
end
