Sequel.migration do
  change do
    alter_table(:webhooks) do
      add_column(:consumer_label, String)
      add_column(:provider_label, String)

      add_constraint(:consumer_label_exclusion, "consumer_id IS NULL OR (consumer_id IS NOT NULL AND consumer_label IS NULL)")
      add_constraint(:provider_label_exclusion, "provider_id IS NULL OR (provider_id IS NOT NULL AND provider_label IS NULL)")
    end
  end
end
