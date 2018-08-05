LATEST_VERIFICATION_IDS_FOR_PROVIDER_VERSIONS_V1 =
  "select pact_version_id, MAX(verification_id) latest_verification_id
    FROM latest_verification_id_for_pact_version_and_provider_version
    GROUP BY pact_version_id"
