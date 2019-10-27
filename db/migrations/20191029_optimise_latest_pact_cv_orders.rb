require_relative '../ddl_statements'

Sequel.migration do
  up do
    create_or_replace_view(:latest_pact_consumer_version_orders,
      latest_pact_consumer_version_orders_v2(self))
  end

  down do
    create_or_replace_view(:latest_pact_consumer_version_orders,
      latest_pact_consumer_version_orders_v1(self))
  end
end
