def head_pact_tags_v1(connection)
  connection.from(Sequel.as(:latest_pact_publication_ids_for_consumer_versions, :lp))
  .join(:versions,{ Sequel[:lp][:consumer_version_id] => Sequel[:cv][:id]}, { table_alias: :cv })
  .join(:latest_tagged_pact_consumer_version_orders, {
    Sequel[:lp][:consumer_id] => Sequel[:o][:consumer_id],
    Sequel[:lp][:provider_id] => Sequel[:o][:provider_id],
    Sequel[:cv][:order] => Sequel[:o][:latest_consumer_version_order]
  }, { table_alias: :o })
  .select(Sequel[:o][:tag_name].as(:name), Sequel[:lp][:pact_publication_id])
end

def head_pact_tags_v2_rollback(connection, postgres)
  if(postgres)
    head_pact_tags_v1(connection).select_append(Sequel.lit("NULL").as(:created_at))
  else
    head_pact_tags_v1(connection)
  end
end

def head_pact_tags_v2(connection)
  connection.from(Sequel.as(:latest_pact_publication_ids_for_consumer_versions, :lp))
  .join(:versions,{ Sequel[:lp][:consumer_version_id] => Sequel[:cv][:id]}, { table_alias: :cv })
  .join(:latest_tagged_pact_consumer_version_orders, {
    Sequel[:lp][:consumer_id] => Sequel[:o][:consumer_id],
    Sequel[:lp][:provider_id] => Sequel[:o][:provider_id],
    Sequel[:cv][:order] => Sequel[:o][:latest_consumer_version_order]
  }, { table_alias: :o } )
  .join(:tags, {
    Sequel[:tags][:version_id] => Sequel[:cv][:id],
    Sequel[:tags][:name] => Sequel[:o][:tag_name]
  })
  .select(Sequel[:o][:tag_name].as(:name), Sequel[:lp][:pact_publication_id], Sequel[:tags][:created_at])
end
