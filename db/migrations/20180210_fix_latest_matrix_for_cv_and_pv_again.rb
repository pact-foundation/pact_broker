Sequel.migration do
  up do
    # In this view there will be one row for each consumer version/provider version
    # Removes 'overwritten' pacts and verifications from the full matrix
    # (ie. only show latest pact revision for each consumer version and
    # latest verification for each provider version)
    # Must include lines where verification_id is null so that we don't
    # lose the unverified pacts.
    # This view used to be (stupidly) called latest_matrix

    # Fix mistakenly copied definition in 20180209_recreate_latest_matrix_for_cv_and_pv_union_all.rb
    # which missed the join to latest_pact_publication_revision_numbers.

    # Change this view to be based on materialized_matrix instead of matrix
    # to speed it up.
    # Note! This does mean there is a dependency on having updated
    # materialized_matrix FIRST that may cause problems. Will see how it goes.

    alter_table(:materialized_matrix) do
      add_index [:verification_id], name: 'ndx_mm_verif_id'
      add_index [:pact_revision_number], name: 'ndx_mm_pact_rev_num'
    end

    create_or_replace_view(:latest_matrix_for_consumer_version_and_provider_version,
      "SELECT matrix.* FROM materialized_matrix matrix
      inner join latest_pact_publication_revision_numbers lr
      on matrix.consumer_id = lr.consumer_id
      and matrix.provider_id = lr.provider_id
      and matrix.consumer_version_order = lr.consumer_version_order
      and matrix.pact_revision_number = lr.latest_revision_number
      INNER JOIN latest_verification_id_for_consumer_version_and_provider_version AS lv
      ON ((matrix.consumer_version_id = lv.consumer_version_id)
      AND (matrix.provider_version_id = lv.provider_version_id)
      AND ((matrix.verification_id = lv.latest_verification_id)))

      UNION ALL

      select matrix.* from materialized_matrix matrix
      inner join latest_pact_publication_revision_numbers lr
      on matrix.consumer_id = lr.consumer_id
      and matrix.provider_id = lr.provider_id
      and matrix.consumer_version_order = lr.consumer_version_order
      and matrix.pact_revision_number = lr.latest_revision_number
      where verification_id is null
      "
    )
    from(:materialized_head_matrix).delete
    from(:materialized_head_matrix).insert(from(:head_matrix).select_all)
  end

  down do
  end
end
