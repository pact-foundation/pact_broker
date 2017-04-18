Sequel.migration do
  change do
    # Latest consumer version order for each consumer/provider pair
    create_or_replace_view(:latest_pact_consumer_version_orders,
      "select provider_id, consumer_id, max(consumer_version_order) as latest_consumer_version_order
      from all_pacts
      group by provider_id, consumer_id"
    )

    # Latest revision number for each consumer version order
    create_or_replace_view(:latest_pact_revision_numbers,
      "select provider_id, consumer_id, consumer_version_order, max(revision_number) as latest_revision_number
      from all_pacts
      group by provider_id, consumer_id, consumer_version_order"
    )

    # Latest revision for each consumer version for each consumer/provider pair
    create_or_replace_view(:latest_pact_revisions,
      "select ap.*
      from all_pacts ap
      inner join latest_pact_revision_numbers lr
      on ap.consumer_id = lr.consumer_id
        and ap.provider_id = lr.provider_id
        and ap.revision_number = lr.latest_revision_number
        and ap.consumer_version_order = lr.consumer_version_order"
    )

    # Latest pacts - most recent revision of most recent consumer version for each consumer/provider pair
    create_or_replace_view(:latest_pacts,
      "select ap.*
      from latest_pact_revisions ap
      inner join latest_pact_consumer_version_orders lp
      on ap.consumer_id = lp.consumer_id
        and ap.provider_id = lp.provider_id
        and ap.consumer_version_order = latest_consumer_version_order
      "
    )
  end
end
