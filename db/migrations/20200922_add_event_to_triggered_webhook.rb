Sequel.migration do
  change do
    add_column(:triggered_webhooks, :event_name, String)
  end
end
