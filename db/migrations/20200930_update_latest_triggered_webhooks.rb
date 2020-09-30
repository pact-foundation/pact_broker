require_relative '../ddl_statements/latest_triggered_webhooks'

Sequel.migration do
  up do
    # TODO
    # drop_view(:latest_triggered_webhook_ids)
    # drop_view(:latest_triggered_webhook_creation_dates)
    create_or_replace_view(:latest_triggered_webhooks, latest_triggered_webhooks_v3)
  end

  down do
    create_or_replace_view(:latest_triggered_webhooks, latest_triggered_webhooks_v3_rollback)
  end
end
