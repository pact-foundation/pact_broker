Sequel.migration do
  up do
    # Latest pact_publication details for each provider/consumer version
    create_or_replace_view(:latest_pact_publications_by_consumer_versions,
      "select app.*
      from latest_pact_publication_ids_for_consumer_versions lpp
      inner join all_pact_publications app
      on lpp.consumer_version_id = app.consumer_version_id
      and lpp.pact_publication_id = app.id
      and lpp.provider_id = app.provider_id"
    )

    # Latest consumer version order for consumer/provider
    # Recreate latest_pact_publication_ids_for_consumer_versions view
    create_or_replace_view(:latest_pact_consumer_version_orders, latest_pact_consumer_version_orders_v2(self))
  end

  down do
    # Latest pact_publication details for each provider/consumer version
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
