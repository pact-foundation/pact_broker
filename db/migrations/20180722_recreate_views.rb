require_relative "../ddl_statements"

Sequel.migration do
  up do
    # Latest pact_publication details for each provider/consumer version
    create_or_replace_view(:latest_pact_publications_by_consumer_versions,
      latest_pact_publications_by_consumer_versions_v2(self))

    # Latest consumer version order for consumer/provider
    # Recreate latest_pact_publication_ids_for_consumer_versions view
    create_or_replace_view(:latest_pact_consumer_version_orders, latest_pact_consumer_version_orders_v2(self))
  end

  down do
    # Latest pact_publication details for each provider/consumer version
    # latest_pact_publications_by_consumer_versions_v1
    create_or_replace_view(:latest_pact_publications_by_consumer_versions,
      "select app.*
      from all_pact_publications app
      inner join latest_pact_publication_revision_numbers lr
      on app.consumer_id = lr.consumer_id
        and app.provider_id = lr.provider_id
        and app.consumer_version_order = lr.consumer_version_order
        and app.revision_number = lr.latest_revision_number"
        )

    create_or_replace_view(:latest_pact_consumer_version_orders,
      latest_pact_consumer_version_orders_v1(self))
  end
end
