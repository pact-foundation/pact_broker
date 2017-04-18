Sequel.migration do
  change do
    create_or_replace_view(:latest_tagged_pact_consumer_version_orders,
      "select provider_id, consumer_id, t.name as tag_name, max(consumer_version_order) as latest_consumer_version_order
      from latest_pact_revisions ap
      inner join tags t
      on t.version_id = ap.consumer_version_id
      group by provider_id, consumer_id, t.name"
    )

    create_or_replace_view(:latest_tagged_pacts,
      "select ap.*, lp.tag_name
      from latest_pact_revisions ap
      inner join latest_tagged_pact_consumer_version_orders lp
      on ap.consumer_id = lp.consumer_id
        and ap.provider_id = lp.provider_id
        and ap.consumer_version_order = latest_consumer_version_order"
    )
  end
end
