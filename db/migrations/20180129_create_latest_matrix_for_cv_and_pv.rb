Sequel.migration do
  up do
    # Removes 'overwritten' pacts and verifications from the matrix
    # (ie. only show latest pact revision for each consumer version and
    # latest verification for each provider version)
    # Must include lines where verification_id is null so that we don't
    # lose the unverified pacts.
    # In this view there will be one row for each consumer version/provider version
    # This view used to be (stupidly) called latest_matrix
    create_view(:latest_matrix_for_consumer_version_and_provider_version,
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

    # it's a bit dodgey to be using the max(id) of the verification to determine the latest,
    # but otherwise we'd need to add an extra step and find the latest_provider_version_order
    # and then find the latest verification within that provider_version_order, which we'd
    # probably do by using the ID anyway. And I'm feeling lazy.
    create_view(:latest_verification_id_for_consumer_version_and_provider,
      "select matrix.consumer_version_id, matrix.provider_id, max(verification_id) as latest_verification_id
      from latest_matrix_for_consumer_version_and_provider_version matrix
      where matrix.verification_id is not null
      group by matrix.consumer_version_id, matrix.provider_id
      "
    )

    # update the definition of latest_matrix to actually be the latest_matrix
    # in the same way that latest_pact_publications is.
    # It contains the latest verification results for the latest pacts.
    create_or_replace_view(:latest_matrix,
      "SELECT matrix.* FROM latest_matrix_for_consumer_version_and_provider_version matrix
      INNER JOIN latest_pact_consumer_version_orders lpcvo
      ON matrix.consumer_id = lpcvo.consumer_id
      AND matrix.provider_id = lpcvo.provider_id
      AND matrix.consumer_version_order = lpcvo.latest_consumer_version_order
      INNER JOIN latest_verification_id_for_consumer_version_and_provider AS lv
      ON ((matrix.consumer_version_id = lv.consumer_version_id)
      AND (matrix.provider_id = lv.provider_id)
      AND ((matrix.verification_id = lv.latest_verification_id)))

      UNION

      SELECT matrix.* FROM latest_matrix_for_consumer_version_and_provider_version matrix
      INNER JOIN latest_pact_consumer_version_orders lpcvo
      ON matrix.consumer_id = lpcvo.consumer_id
      AND matrix.provider_id = lpcvo.provider_id
      AND matrix.consumer_version_order = lpcvo.latest_consumer_version_order
      where verification_id is null
      "
    )
  end

  down do
    # revert to previous crappy definition
    create_or_replace_view(:latest_matrix,
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

    drop_view(:latest_verification_id_for_consumer_version_and_provider)
    drop_view(:latest_matrix_for_consumer_version_and_provider_version)
  end
end