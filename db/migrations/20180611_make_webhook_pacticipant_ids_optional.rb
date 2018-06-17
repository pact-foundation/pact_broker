Sequel.migration do
  up do
    alter_table(:webhooks) do
      set_column_allow_null(:consumer_id)
      set_column_allow_null(:provider_id)
    end
  end

  down do
  end
end
