Sequel.migration do
  up do
    alter_table(:branch_versions) do
      add_column(:auto_created, TrueClass, default: false)
    end

    alter_table(:deployed_versions) do
      add_column(:auto_created, TrueClass, default: false)
    end

    from(:branch_versions).update(auto_created: true)
    from(:deployed_versions).update(auto_created: true)
  end

  down do
    alter_table(:branch_versions) do
      drop_column(:auto_created)
    end

    alter_table(:deployed_versions) do
      drop_column(:auto_created)
    end
  end
end
