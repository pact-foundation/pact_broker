Sequel.migration do
  up do
    alter_table(:branch_versions) do
      drop_index :branch_versions_branch_name_index
    end
  end

  down do
    alter_table(:branch_versions_branch_name_index) do
      add_index :branch_versions_branch_name_index, :branch_name
    end
  end
end
