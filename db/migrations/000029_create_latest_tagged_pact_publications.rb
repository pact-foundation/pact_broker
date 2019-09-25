Sequel.migration do
  up do
    # The pact for the latest consumer version (ordered by consumer version order) *that has a pact* for each tag
    # eg. For each tag, find all the consumer versions that have pacts, order them by consumer version order, then get the pact for the latest consumer version.
    create_or_replace_view(:latest_tagged_pact_consumer_version_orders,
      "select provider_id, consumer_id, t.name as tag_name, max(consumer_version_order) as latest_consumer_version_order
      from latest_pact_publications_by_consumer_versions ap
      inner join tags t
      on t.version_id = ap.consumer_version_id
      group by provider_id, consumer_id, t.name"
    )

    create_view(:latest_tagged_pact_publications,
      "select lp.*, o.tag_name
      from latest_pact_publications_by_consumer_versions lp
      inner join latest_tagged_pact_consumer_version_orders o
      on lp.consumer_id = o.consumer_id
        and lp.provider_id = o.provider_id
        and lp.consumer_version_order = latest_consumer_version_order"
    )
  end
end
