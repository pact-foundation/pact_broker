require_relative '../ddl_statements/latest_triggered_webhooks'

Sequel.migration do
  up do

    create_or_replace_view(:latest_triggered_webhook_creation_dates, latest_triggered_webhook_creation_dates_v2)
    create_or_replace_view(:latest_triggered_webhook_ids, latest_triggered_webhook_ids_v2)
    create_or_replace_view(:latest_triggered_webhooks, latest_triggered_webhooks_v2)
  end

  down do
    create_or_replace_view(:latest_triggered_webhook_ids,
      "select webhook_uuid, consumer_id, provider_id, max(created_at) as latest_triggered_webhook_created_at
      from triggered_webhooks
      group by webhook_uuid, consumer_id, provider_id"
    )

    create_or_replace_view(:latest_triggered_webhooks,
      "select tw.*
      from triggered_webhooks tw
      inner join latest_triggered_webhook_ids ltwi
      on tw.consumer_id = ltwi.consumer_id
      and tw.provider_id = ltwi.provider_id
      and tw.webhook_uuid = ltwi.webhook_uuid
      and tw.created_at = ltwi.latest_triggered_webhook_created_at"
    )

    drop_view(:latest_triggered_webhook_creation_dates)
  end
end