Sequel.migration do
  up do
    create_or_replace_view(:latest_verification_ids_for_consumer_version_tags,
    "select
      v.provider_id,
      v.consumer_id,
      t.name as consumer_version_tag_name,
      max(v.verification_id) as latest_verification_id
    from latest_verification_id_for_pact_version_and_provider_version v
    join latest_pact_publication_ids_by_consumer_versions lpp
      on v.pact_version_id = lpp.pact_version_id
    join tags t
      on lpp.consumer_version_id = t.version_id
    group by v.provider_id, v.consumer_id, t.name")
  end

  down do
    # The latest verification id for each consumer version tag
    create_or_replace_view(:latest_verification_ids_for_consumer_version_tags,
      "select
        pv.pacticipant_id as provider_id,
        lpp.consumer_id,
        t.name as consumer_version_tag_name,
        max(v.id) as latest_verification_id
      from verifications v
      join latest_pact_publications_by_consumer_versions lpp
        on v.pact_version_id = lpp.pact_version_id
      join tags t
        on lpp.consumer_version_id = t.version_id
      join versions pv
        on v.provider_version_id = pv.id
      group by pv.pacticipant_id, lpp.consumer_id, t.name")
  end
end
