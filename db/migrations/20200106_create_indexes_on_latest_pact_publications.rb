Sequel.migration do
  up do
    alter_table(:latest_pact_publication_ids_for_consumer_versions) do
      add_index [:consumer_id], name: 'ndx_latest_pact_publications_consumer_id'
      add_index [:provider_id], name: 'ndx_latest_pact_publications_provider_id'
      add_index [:consumer_version_id], name: 'ndx_latest_pact_publications_cv_id'
    end
  end

  down do
    alter_table(:latest_pact_publication_ids_for_consumer_versions) do
      drop_index [:consumer_id], name: 'ndx_latest_pact_publications_consumer_id'
      drop_index [:provider_id], name: 'ndx_latest_pact_publications_provider_id'
      drop_index [:consumer_version_id], name: 'ndx_latest_pact_publications_cv_id'
    end
  end
end
