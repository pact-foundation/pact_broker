Sequel.migration do
  up do
    alter_table(:integrations) do
      add_index([:provider_id, :consumer_id], unique: true, name: "integrations_consumer_id_provider_id_unique")
    end
  end

  down do
    alter_table(:integrations) do
      drop_index([:provider_id, :consumer_id], name: "integrations_consumer_id_provider_id_unique")
    end
  end
end
