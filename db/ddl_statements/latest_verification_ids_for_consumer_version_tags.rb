# The latest verification id for each consumer version tag
# This is not:
#   find latest pacticipant version with given tag
#     -> find the latest pact
#     -> find the latest verification
# because the latest pacticipant version with the tag might not have a pact,
# and the latest pact might not have a verification.

# This is:
# join the tags and the pacticipant versions and the verifications and find the "latest" row

LATEST_VERIFICATION_IDS_FOR_CONSUMER_VERSION_TAGS_V1 = "select
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
      group by pv.pacticipant_id, lpp.consumer_id, t.name"

LATEST_VERIFICATION_IDS_FOR_CONSUMER_VERSION_TAGS_V2 = "select
        pv.pacticipant_id as provider_id,
        lpp.consumer_id,
        t.name as consumer_version_tag_name,
        max(v.id) as latest_verification_id
      from verifications v
      join latest_pact_publication_ids_for_consumer_versions lpp
        on v.pact_version_id = lpp.pact_version_id
      join tags t
        on lpp.consumer_version_id = t.version_id
      join versions pv
        on v.provider_version_id = pv.id
      group by pv.pacticipant_id, lpp.consumer_id, t.name"

LATEST_VERIFICATION_IDS_FOR_CONSUMER_VERSION_TAGS_V3 = "select
        pv.pacticipant_id as provider_id,
        lpp.consumer_id,
        t.name as consumer_version_tag_name,
        max(v.id) as latest_verification_id
      from verifications v
      join latest_pact_publication_ids_for_consumer_versions lpp
        on v.pact_version_id = lpp.pact_version_id
      join tags t
        on lpp.consumer_version_id = t.version_id
      join versions pv
        on v.provider_version_id = pv.id
      where v.id in (select latest_verification_id from latest_verification_ids_for_pact_versions)
      group by pv.pacticipant_id, lpp.consumer_id, t.name"


LATEST_VERIFICATION_IDS_FOR_CONSUMER_VERSION_TAGS_V4 = "select
    lpp.provider_id,
    lpp.consumer_id,
    t.name as consumer_version_tag_name,
    max(lv.latest_verification_id)
  from latest_verification_ids_for_pact_versions lv
  join latest_pact_publication_ids_for_consumer_versions lpp
    on lv.pact_version_id = lpp.pact_version_id
  join tags t
    on lpp.consumer_version_id = t.version_id
  group by lpp.provider_id, lpp.consumer_id, t.name
"
