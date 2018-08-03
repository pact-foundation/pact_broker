Sequel.migration do
  up do
    # Latest verification_id for each pact version/provider version.
    # Keeping track of this in a table rather than having to calculate the
    # latest revision speeds queries up.
    # There is no way to delete an individual verification result yet, but when there
    # is, we'll need to re-calculate the latest.
    create_table(:latest_verif_id_for_pact_version_and_provider_version, charset: 'utf8') do
      foreign_key :consumer_id, :pacticipants, nil: false, on_delete: :cascade # not required, but useful to avoid extra joins
      foreign_key :pact_version_id, :pact_versions, nil: false, on_delete: :cascade
      foreign_key :provider_id, :pacticipants, nil: false, on_delete: :cascade # not required, but useful to avoid extra joins
      foreign_key :provider_version_id, :versions, nil: false, on_delete: :cascade
      foreign_key :verification_id, :verifications, nil: false, on_delete: :cascade, unique: true
      index [:pact_version_id, :provider_version_id], unique: true, name: "unq_latest_verifid_pvid_provid"
    end
  end

  down do
    drop_table(:latest_verif_id_for_pact_version_and_provider_version)
  end
end
