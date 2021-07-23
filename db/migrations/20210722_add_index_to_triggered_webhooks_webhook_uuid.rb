Sequel.migration do
  change do
    alter_table(:triggered_webhooks) do
      add_index([:webhook_uuid], name: "triggered_webhooks_webhook_uuid_index")
    end
  end
end
