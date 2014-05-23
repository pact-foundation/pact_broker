Sequel.migration do
  change do
    create_view(:all_pacts,
      "select pact.id, c.id as consumer_id, c.name as consumer_name, cv.number as consumer_version_number, cv.`order` as consumer_version_order, p.id as provider_id, p.name as provider_name, pact.json_content
      from pacts pact
      join versions cv on pact.version_id = cv.id
      join pacticipants c on cv.pacticipant_id = c.id
      join pacticipants p on pact.provider_id = p.id")

    create_view(:latest_pact_consumer_version_orders,
      "select provider_id, consumer_id, max(consumer_version_order) as latest_consumer_version_order
      from all_pacts
      group by provider_id, consumer_id"
    )

    create_view(:latest_pacts,
      "select ap.*
      from all_pacts ap
      inner join latest_pact_consumer_version_orders lp
      on ap.consumer_id = lp.consumer_id
           and ap.provider_id = lp.provider_id
           and ap.consumer_version_order = latest_consumer_version_order"
    )
  end
end

