Sequel.migration do
  up do
    alter_table(:deployed_versions) do
      set_column_not_null(:created_at)
      set_column_not_null(:updated_at)
    end

    alter_table(:environments) do
      set_column_not_null(:uuid)
      set_column_not_null(:name)
      set_column_not_null(:production)
      set_column_not_null(:created_at)
      set_column_not_null(:updated_at)
    end
  end

  down do
    alter_table(:deployed_versions) do
      set_column_allow_null(:created_at)
      set_column_allow_null(:updated_at)
    end

    alter_table(:environments) do
      set_column_allow_null(:uuid)
      set_column_allow_null(:name)
      set_column_allow_null(:production)
      set_column_allow_null(:created_at)
      set_column_allow_null(:updated_at)
    end
  end
end
