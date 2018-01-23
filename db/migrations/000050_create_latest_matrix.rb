Sequel.migration do
  change do
    # Removes 'overwritten' pacts and verifications from the matrix
    # (ie. only show latest pact revision for each consumer version and
    # latest verification for each provider version)
    # Must include lines where verification_id is null so that we don't
    # lose the unverified pacts.
    # In this view there will be one row for each consumer version/provider version
    create_view(:latest_matrix,
      "SELECT matrix.* FROM matrix
      INNER JOIN latest_verification_id_for_consumer_version_and_provider_version AS lv
      ON ((matrix.consumer_version_id = lv.consumer_version_id)
      AND (matrix.provider_version_id = lv.provider_version_id)
      AND ((matrix.verification_id = lv.latest_verification_id)))

      UNION

      select matrix.* from matrix
      inner join latest_pact_publication_revision_numbers lr
      on matrix.consumer_id = lr.consumer_id
      and matrix.provider_id = lr.provider_id
      and matrix.consumer_version_order = lr.consumer_version_order
      and matrix.pact_revision_number = lr.latest_revision_number
      where verification_id is null
      "
    )
  end
end
