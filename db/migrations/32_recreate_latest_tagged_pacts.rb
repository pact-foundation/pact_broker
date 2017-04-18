Sequel.migration do
  up do
    create_or_replace_view(:latest_tagged_pacts,
      "select ap.*, lp.tag_name
      from all_pacts ap
      inner join latest_tagged_pact_consumer_version_orders lp
      on ap.consumer_id = lp.consumer_id
        and ap.provider_id = lp.provider_id
        and ap.consumer_version_order = latest_consumer_version_order"
    )
  end
end
