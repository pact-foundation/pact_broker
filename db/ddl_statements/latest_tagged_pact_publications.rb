LATEST_TAGGED_PACT_PUBLICATIONS = "select lp.*, o.tag_name
      from latest_pact_publications_by_consumer_versions lp
      inner join latest_tagged_pact_consumer_version_orders o
      on lp.consumer_id = o.consumer_id
        and lp.provider_id = o.provider_id
        and lp.consumer_version_order = latest_consumer_version_order"
