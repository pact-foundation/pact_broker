Sequel.migration do
  up do
    # Latest verification_id for each pact version/provider version.
    # Keeping track of this in a table rather than having to calculate the
    # latest revision speeds queries up.
    # There is no way to delete an individual verification result yet, but when there
    # is, we'll need to re-calculate the latest.
    create_table(:latest_verification_id_for_pact_version_and_provider_version, charset: 'utf8') do
      foreign_key :consumer_id, :pacticipants,      null: false, on_delete: :cascade, foreign_key_constraint_name: 'latest_v_id_for_pv_and_pv_consumer_id_fk' # not required, but useful to avoid extra joins
      foreign_key :pact_version_id, :pact_versions, null: false, on_delete: :cascade, foreign_key_constraint_name: 'latest_v_id_for_pv_and_pv_pact_version_id_fk'
      foreign_key :provider_id, :pacticipants,      null: false, on_delete: :cascade, foreign_key_constraint_name: 'latest_v_id_for_pv_and_pv_provider_id_fk'  # not required, but useful to avoid extra joins
      foreign_key :provider_version_id, :versions,  null: false, on_delete: :cascade, foreign_key_constraint_name: 'latest_v_id_for_pv_and_pv_provider_version_id_fk'
      foreign_key :verification_id, :verifications, null: false, on_delete: :cascade, foreign_key_constraint_name: 'latest_v_id_for_pv_and_pv_verification_id_fk'
      index [:verification_id], unique: true, name: "latest_v_id_for_pv_and_pv_v_id_unq"
      index [:pact_version_id, :provider_version_id], unique: true, name: "latest_v_id_for_pv_and_pv_pv_id_pv_id_unq"
      index [:pact_version_id, :verification_id], name: "latest_v_id_for_pv_and_pv_pv_id_v_id"
    end
  end

  down do
    drop_table(:latest_verification_id_for_pact_version_and_provider_version)
  end
end
