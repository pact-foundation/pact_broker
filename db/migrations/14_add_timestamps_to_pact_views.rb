Sequel.migration do
  change do
    create_or_replace_view(:all_pacts,
      "select pacts.id,
      c.id as consumer_id, c.name as consumer_name,
      cv.number as consumer_version_number, cv.`order` as consumer_version_order,
      p.id as provider_id, p.name as provider_name,
      pacts.json_content, pacts.created_at, pacts.updated_at
      from pacts
      inner join versions as cv on (cv.id = pacts.version_id)
      inner join pacticipants as c on (c.id = cv.pacticipant_id)
      inner join pacticipants as p on (p.id = pacts.provider_id)")

    create_or_replace_view(:latest_pact_consumer_version_orders,
      "select provider_id, consumer_id, max(consumer_version_order) as latest_consumer_version_order
      from all_pacts
      group by provider_id, consumer_id"
    )

    create_or_replace_view(:latest_pacts,
      "select ap.*
      from all_pacts ap
      inner join latest_pact_consumer_version_orders lp
      on ap.consumer_id = lp.consumer_id
           and ap.provider_id = lp.provider_id
           and ap.consumer_version_order = latest_consumer_version_order"
    )
  end
end

