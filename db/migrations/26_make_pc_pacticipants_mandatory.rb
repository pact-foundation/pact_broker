Sequel.migration do
  up do
    alter_table(:pact_contents) do
      set_column_not_null(:consumer_id)
      set_column_not_null(:provider_id)
    end
  end
end
