Sequel.migration do
  up do
    # The latest verification id for each consumer version tag
    create_or_replace_view(:latest_verification_ids_for_consumer_and_provider,
      "select
        provider_id,
        consumer_id,
        max(id) as latest_verification_id
        from verifications v
        group by provider_id, consumer_id")
  end

  down do
    # The latest verification id for each consumer version tag
    create_or_replace_view(:latest_verification_ids_for_consumer_and_provider,
      "select
        pv.pacticipant_id as provider_id,
        lpp.consumer_id,
        max(v.id) as latest_verification_id
      from verifications v
      join latest_pact_publications_by_consumer_versions lpp
        on v.pact_version_id = lpp.pact_version_id
      join versions pv
        on v.provider_version_id = pv.id
      group by pv.pacticipant_id, lpp.consumer_id")
  end
end
