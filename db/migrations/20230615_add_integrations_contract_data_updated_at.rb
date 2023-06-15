Sequel.migration do
  up do
    alter_table(:integrations) do
      add_column(:contract_data_updated_at, DateTime)
    end
  end

  down do
    alter_table(:integrations) do
      drop_column(:contract_data_updated_at)
    end
  end
end
