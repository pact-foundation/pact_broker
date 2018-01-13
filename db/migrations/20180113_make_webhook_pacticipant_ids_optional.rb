Sequel.migration do
  up do
    alter_table(:webhooks) do
      set_column_allow_null(:consumer_id)
      set_column_allow_null(:provider_id)
    end

    alter_table(:triggered_webhooks) do
      set_column_allow_null(:consumer_id)
      set_column_allow_null(:provider_id)
    end

    create_or_replace_view(:latest_triggered_webhooks,
      "select tw.*
        from triggered_webhooks tw
        inner join latest_triggered_webhook_ids ltwi
        on tw.consumer_id = ltwi.consumer_id
        and tw.provider_id = ltwi.provider_id
        and tw.webhook_uuid = ltwi.webhook_uuid
        and tw.created_at = ltwi.latest_triggered_webhook_created_at

        union

        select tw.*
        from triggered_webhooks tw
        inner join latest_triggered_webhook_ids ltwi
        on tw.consumer_id = ltwi.consumer_id
        and tw.webhook_uuid = ltwi.webhook_uuid
        and tw.created_at = ltwi.latest_triggered_webhook_created_at
        where tw.provider_id is null
        and ltwi.provider_id is null

        union

        select tw.*
        from triggered_webhooks tw
        inner join latest_triggered_webhook_ids ltwi
        on tw.provider_id = ltwi.provider_id
        and tw.webhook_uuid = ltwi.webhook_uuid
        and tw.created_at = ltwi.latest_triggered_webhook_created_at
        where tw.consumer_id is null
        and ltwi.consumer_id is null"
    )
  end

  down do
  end
end
