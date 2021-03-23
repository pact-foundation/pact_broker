Sequel.migration do
  change do
    alter_table(:webhooks) do
      add_column(:consumer_version_matchers, String)
    end
  end
end
