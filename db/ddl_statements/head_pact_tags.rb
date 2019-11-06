def head_pact_tags_v1(connection)
  connection.from(Sequel.as(:latest_pact_publication_ids_for_consumer_versions, :lp))
  .join(:versions,{ Sequel[:lp][:consumer_version_id] => Sequel[:cv][:id]}, { table_alias: :cv })
  .join(:latest_tagged_pact_consumer_version_orders, {
    Sequel[:lp][:consumer_id] => Sequel[:o][:consumer_id],
    Sequel[:lp][:provider_id] => Sequel[:o][:provider_id],
    Sequel[:cv][:order] => Sequel[:o][:latest_consumer_version_order]
  }, { table_alias: :o})
  .select(Sequel[:o][:tag_name].as(:name), Sequel[:lp][:pact_publication_id])
end
