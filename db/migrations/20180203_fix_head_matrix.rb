Sequel.migration do
  up do
    # A row for each of the latest pact publications,
    # and a row for each of the latest tagged pact publications.
    # This definition fixes the missing revision number join in
    # 20180201_create_head_matrix.rb
    create_or_replace_view(:head_matrix,
      "SELECT matrix.*, hpp.tag_name as consumer_tag_name
      FROM latest_matrix_for_consumer_version_and_provider_version matrix
      INNER JOIN head_pact_publications hpp
      ON matrix.consumer_id = hpp.consumer_id
      AND matrix.provider_id = hpp.provider_id
      AND matrix.consumer_version_order = hpp.consumer_version_order
      AND matrix.pact_revision_number = hpp.revision_number
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
      AND matrix.pact_revision_number = hpp.revision_number
      where verification_id is null
      "
    )
  end

  down do
  end
end
