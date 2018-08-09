Sequel.migration do
  up do
    # Latest pact_publication (revision) for each provider/consumer version.
    # Keeping track of this in a table rather than having to calculate the
    # latest revision speeds things up.
    # We don't have to worry about updating it if a revision is deleted, because
    # you can't delete a single pact revision through the API - all the revisions
    # for a pact are deleted together when you delete the pact resource for that
    # consumer version, and when that happens, this row will cascade delete.

    create_table(:latest_pact_publication_ids_for_consumer_versions, charset: 'utf8') do
      foreign_key :consumer_id, :pacticipants, null: false, on_delete: :cascade # redundant, but speeds up queries by removing need for extra join
      foreign_key :consumer_version_id, :versions, null: false, on_delete: :cascade
      foreign_key :provider_id, :pacticipants, null: false, on_delete: :cascade
      foreign_key :pact_publication_id, :pact_publications, null: false, on_delete: :cascade, unique: true
      foreign_key :pact_version_id, :pact_versions, null: false, on_delete: :cascade
      index [:provider_id, :consumer_version_id], unique: true, name: "unq_latest_ppid_prov_conver"
      index [:provider_id, :consumer_id], name: "lpp_provider_id_consumer_id_index"
    end
  end

  down do
    drop_table(:latest_pact_publication_ids_for_consumer_versions)
  end
end
