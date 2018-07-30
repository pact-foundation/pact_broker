Sequel.migration do
  up do
    # The danger with this migration is that a pact publication created by an old node will be lost
    rows = from(:latest_pact_publications_by_consumer_versions).select(:consumer_version_id, :provider_id, :id)
    from(:latest_pact_publication_ids_by_consumer_versions).insert(rows)
  end

  down do

  end
end
