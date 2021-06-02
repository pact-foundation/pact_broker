require_relative "../ddl_statements"

Sequel.migration do
  up do
    create_or_replace_view(:latest_tagged_pact_consumer_version_orders,
      latest_tagged_pact_consumer_version_orders_v4(self))
  end

  down do
    create_or_replace_view(:latest_tagged_pact_consumer_version_orders,
      latest_tagged_pact_consumer_version_orders_v3(self))
  end
end
