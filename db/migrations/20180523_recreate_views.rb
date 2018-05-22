Sequel.migration do
  up do
    # joining with latest_pact_publication_revision_numbers gets rid of the overwritten
    # pact revisions, and the max(verification_id) gets rid of the overwritten
    # verifications
    create_or_replace_view(:latest_verification_id_for_consumer_version_and_provider_version,
      "select pp.consumer_version_id, lv.provider_version_id, lv.verification_id as latest_verification_id
      from latest_pact_publication_ids_by_consumer_versions lpp
      inner join pact_publications pp
        on pp.id = lpp.pact_publication_id
      left outer join latest_verification_id_for_pact_version_and_provider_version lv
          on lv.pact_version_id = pp.pact_version_id"
    )

    #TODO
    #drop_view(:latest_matrix)
    #drop_view(:latest_verification_id_for_consumer_version_and_provider)
    #drop_view(:latest_matrix_for_consumer_version_and_provider_version)

  end

  down do
    create_or_replace_view(:latest_verification_id_for_consumer_version_and_provider_version,
          "select consumer_version_id, provider_version_id, max(verification_id) as latest_verification_id
          from matrix
          inner join latest_pact_publication_revision_numbers lr
            on matrix.consumer_id = lr.consumer_id
            and matrix.provider_id = lr.provider_id
            and matrix.consumer_version_order = lr.consumer_version_order
            and matrix.pact_revision_number = lr.latest_revision_number
            group by consumer_version_id, provider_version_id"
        )

  end
end
