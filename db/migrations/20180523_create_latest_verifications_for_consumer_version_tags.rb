Sequel.migration do
  up do
    # The latest verification id for each consumer version tag
    create_view(:latest_verifications_ids_for_consumer_version_tags,
      "select t.name as consumer_version_tag_name, max(lv.id) as latest_verification_id
      from verifications lv
      join latest_pact_publications_by_consumer_versions lpp
      on lv.pact_version_id = lpp.pact_version_id
      join tags t on lpp.consumer_version_id = t.version_id
      group by t.name")

    # The latest verification for each consumer version tag
    create_view(:latest_verifications_for_consumer_version_tags,
      "select v.*, lv.consumer_version_tag_name
      from verifications v
      join latest_verifications_ids_for_consumer_version_tags lv
      on lv.latest_verification_id = v.id")
  end

  down do
    drop_view(:latest_verifications_for_consumer_version_tags)
    drop_view(:latest_verifications_ids_for_consumer_version_tags)
  end
end
