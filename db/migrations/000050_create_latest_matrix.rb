Sequel.migration do
  change do
    # Removes 'overwritten' pacts and verifications from the matrix
    # (ie. only show latest pact revision for each consumer version and
    # latest verification for each provider version)
    # Must include lines where verification_id is null so that we don't
    # lose the unverified pacts.
    create_view(:latest_matrix,
      "SELECT matrix.* FROM matrix
      INNER JOIN latest_verification_id_for_consumer_version_and_provider_version AS lv
      ON ((matrix.consumer_version_id = lv.consumer_version_id)
      AND (matrix.provider_version_id = lv.provider_version_id)
      AND ((matrix.verification_id = lv.latest_verification_id)))

      UNION

      select * from matrix where verification_id is null"
    )
  end
end
