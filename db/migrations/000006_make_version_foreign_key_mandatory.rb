Sequel.migration do
  change do
    alter_table(:tags) do
      set_column_not_null(:version_id)
    end
  end
end

