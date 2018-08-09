Sequel.migration do
  up do
    from(:materialized_matrix).delete
    from(:materialized_head_matrix).delete

    # TODO
    # drop_view(:latest_matrix)
    # drop_view(:latest_verification_id_for_consumer_version_and_provider)
    # drop_view(:latest_matrix_for_consumer_version_and_provider_version)
    # drop_table(:materialized_matrix)
    # drop_table(:materialized_head_matrix)
  end

  down do
    from(:materialized_matrix).delete
    from(:materialized_matrix).insert(from(:matrix).select_all)
    from(:materialized_head_matrix).delete
    from(:materialized_head_matrix).insert(from(:head_matrix).select_all)
  end
end
