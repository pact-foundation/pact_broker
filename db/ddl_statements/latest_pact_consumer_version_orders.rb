# The consumer id, provider id, and consumer version order
# for the latest consumer version that has a pact with that provider.

def latest_pact_consumer_version_orders_v1(connection = nil)
  "select provider_id, consumer_id, max(consumer_version_order) as latest_consumer_version_order
  from all_pact_publications
  group by provider_id, consumer_id"
end

def latest_pact_consumer_version_orders_v2(connection = nil)
  view = Sequel.as(:latest_pact_publication_ids_for_consumer_versions, :lp)
  connection.from(view)
    .select_group(:provider_id, :consumer_id)
    .select_append{ max(order).as(latest_consumer_version_order) }
    .join(:versions, { Sequel[:lp][:consumer_version_id] => Sequel[:cv][:id]}, { table_alias: :cv } )
end
