Sequel.migration do
  change do
    alter_table(:triggered_webhooks) do
      add_foreign_key(:verification_id, :verifications)
    end
  end
end
