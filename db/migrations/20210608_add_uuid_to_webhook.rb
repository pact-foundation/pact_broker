Sequel.migration do
  up do
    alter_table(:triggered_webhooks) do
      add_column(:uuid, String)
      add_index [:uuid], name: "triggered_webhooks_uuid", unique: true
    end
  end

  down do
    alter_table(:triggered_webhooks) do
      drop_index([:uuid], name: "triggered_webhooks_uuid", unique: true)
      drop_column(:uuid)
    end
  end
end
