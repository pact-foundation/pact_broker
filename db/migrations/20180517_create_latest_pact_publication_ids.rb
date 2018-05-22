Sequel.migration do
  up do
    # Latest pact_publication (revision) for each provider/consumer version.
    # Keeping track of this in a table rather than having to calculate the
    # latest revision speeds things up.
    # We don't have to worry about updating it if a revision is deleted, because
    # you can't delete a single revision through the API - all the revisions
    # for a pact are deleted together when you delete the pact resource for that
    # consumer version, and when that happens, this row will cascade delete.
    create_table(:latest_pact_publication_ids_by_consumer_versions, charset: 'utf8') do
      foreign_key :consumer_version_id, :versions, nil: false, on_delete: :cascade
      foreign_key :provider_id, :pacticipants, nil: false, on_delete: :cascade
      foreign_key :pact_publication_id, :pact_publications, nil: false, on_delete: :cascade, unique: true
      index [:provider_id, :consumer_version_id], unique: true, name: "unq_latest_ppid_prov_conver"
    end
  end

  down do
    drop_table(:latest_pact_publication_ids_by_consumer_versions)
  end
end
