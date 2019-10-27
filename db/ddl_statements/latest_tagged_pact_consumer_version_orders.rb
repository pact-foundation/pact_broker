def latest_tagged_pact_consumer_version_orders_v2(connection)
  pp = :pact_publications
  connection.from(pp)
    .select_group(
      Sequel[pp][:provider_id],
      Sequel[:cv][:pacticipant_id].as(:consumer_id),
      Sequel[:t][:name].as(:tag_name))
    .select_append{ max(order).as(latest_consumer_version_order) }
    .join(:versions, { Sequel[pp][:consumer_version_id] => Sequel[:cv][:id] }, { table_alias: :cv} )
    .join(:tags, { Sequel[:t][:version_id] => Sequel[pp][:consumer_version_id] }, { table_alias: :t })
end

def latest_tagged_pact_consumer_version_orders_v3(connection)
  view = Sequel.as(:latest_pact_publication_ids_for_consumer_versions, :lp)
  connection.from(view)
    .select_group(
      Sequel[:lp][:provider_id],
      Sequel[:cv][:pacticipant_id].as(:consumer_id),
      Sequel[:t][:name].as(:tag_name))
    .select_append{ max(order).as(latest_consumer_version_order) }
    .join(:versions, { Sequel[:lp][:consumer_version_id] => Sequel[:cv][:id] }, { table_alias: :cv} )
    .join(:tags, { Sequel[:t][:version_id] => Sequel[:lp][:consumer_version_id] }, { table_alias: :t })
end
