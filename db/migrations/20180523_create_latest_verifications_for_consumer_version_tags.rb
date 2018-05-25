Sequel.migration do
  up do
    # The latest verification id for each consumer version tag
    create_view(:latest_verifications_ids_for_consumer_version_tags,
      "select pv.pacticipant_id as provider_id, lpp.consumer_id, t.name as consumer_version_tag_name, max(v.id) as latest_verification_id
      from verifications v
      join latest_pact_publications_by_consumer_versions lpp
        on v.pact_version_id = lpp.pact_version_id
      join tags t
        on lpp.consumer_version_id = t.version_id
      join versions pv
        on v.provider_version_id = pv.id
      group by pv.pacticipant_id, lpp.consumer_id, t.name")

    # The latest verification for each consumer version tag
    create_view(:latest_verifications_for_consumer_version_tags,
      "select v.*, lv.provider_id, lv.consumer_id, lv.consumer_version_tag_name
      from verifications v
      join latest_verifications_ids_for_consumer_version_tags lv
        on lv.latest_verification_id = v.id")
  end

  down do
    drop_view(:latest_verifications_for_consumer_version_tags)
    drop_view(:latest_verifications_ids_for_consumer_version_tags)
  end
end
