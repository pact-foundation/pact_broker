Sequel.migration do
  up do
    # a row for each of the latest pact publications,
    # and a row for each of the latest tagged pact publications
    drop_view(:head_matrix)
    create_view(:head_matrix,
      "SELECT matrix.*, hpp.tag_name as consumer_version_tag_name
      FROM latest_matrix_for_consumer_version_and_provider_version matrix
      INNER JOIN head_pact_publications hpp
      ON matrix.consumer_id = hpp.consumer_id
      AND matrix.provider_id = hpp.provider_id
      AND matrix.consumer_version_order = hpp.consumer_version_order
      INNER JOIN latest_verification_id_for_consumer_version_and_provider AS lv
      ON matrix.consumer_version_id = lv.consumer_version_id
      AND matrix.provider_id = lv.provider_id
      AND matrix.verification_id = lv.latest_verification_id

      UNION

      SELECT matrix.*, hpp.tag_name as consumer_version_tag_name
      FROM latest_matrix_for_consumer_version_and_provider_version matrix
      INNER JOIN head_pact_publications hpp
      ON matrix.consumer_id = hpp.consumer_id
      AND matrix.provider_id = hpp.provider_id
      AND matrix.consumer_version_order = hpp.consumer_version_order
      where verification_id is null
      "
    )

    alter_table(:materialized_head_matrix) do
      rename_column(:consumer_tag_name, :consumer_version_tag_name)
    end
  end

  down do
    alter_table(:materialized_head_matrix) do
      rename_column(:consumer_version_tag_name, :consumer_tag_name)
    end

    drop_view(:head_matrix)
    create_view(:head_matrix,
      "SELECT matrix.*, hpp.tag_name as consumer_tag_name
      FROM latest_matrix_for_consumer_version_and_provider_version matrix
      INNER JOIN head_pact_publications hpp
      ON matrix.consumer_id = hpp.consumer_id
      AND matrix.provider_id = hpp.provider_id
      AND matrix.consumer_version_order = hpp.consumer_version_order
      INNER JOIN latest_verification_id_for_consumer_version_and_provider AS lv
      ON matrix.consumer_version_id = lv.consumer_version_id
      AND matrix.provider_id = lv.provider_id
      AND matrix.verification_id = lv.latest_verification_id

      UNION

      SELECT matrix.*, hpp.tag_name as consumer_tag_name
      FROM latest_matrix_for_consumer_version_and_provider_version matrix
      INNER JOIN head_pact_publications hpp
      ON matrix.consumer_id = hpp.consumer_id
      AND matrix.provider_id = hpp.provider_id
      AND matrix.consumer_version_order = hpp.consumer_version_order
      where verification_id is null
      "
    )

    from(:materialized_head_matrix).delete
    from(:materialized_head_matrix).insert(from(:head_matrix).select_all)
  end
end
