LATEST_VERIFICATION_IDS_FOR_CONSUMER_AND_PROVIDER_V1 = "select
        pv.pacticipant_id as provider_id,
        lpp.consumer_id,
        max(v.id) as latest_verification_id
      from verifications v
      join latest_pact_publications_by_consumer_versions lpp
        on v.pact_version_id = lpp.pact_version_id
      join versions pv
        on v.provider_version_id = pv.id
      group by pv.pacticipant_id, lpp.consumer_id"

LATEST_VERIFICATION_IDS_FOR_CONSUMER_AND_PROVIDER_V2 = "select
        provider_id,
        consumer_id,
        max(id) as latest_verification_id
        from verifications v
        group by provider_id, consumer_id"


LATEST_VERIFICATION_IDS_FOR_CONSUMER_AND_PROVIDER_V3 = "select
        provider_id,
        consumer_id,
        max(verification_id) as latest_verification_id
        from latest_verification_id_for_pact_version_and_provider_version v
        group by provider_id, consumer_id"
