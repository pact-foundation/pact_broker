Sequel.migration do
  change do
    alter_table(:tags) do
      set_column_not_null(:created_at)
      set_column_not_null(:updated_at)
    end
    alter_table(:pacticipants) do
      set_column_not_null(:created_at)
      set_column_not_null(:updated_at)
    end
    alter_table(:versions) do
      set_column_not_null(:created_at)
      set_column_not_null(:updated_at)
    end
    alter_table(:pacts) do
      set_column_not_null(:created_at)
      set_column_not_null(:updated_at)
    end
  end
end
