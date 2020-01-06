Sequel.migration do
  up do
    alter_table(:latest_verification_id_for_pact_version_and_provider_version) do
      add_index [:consumer_id], name: 'ndx_latest_verification_consumer_id'
      add_index [:provider_id], name: 'ndx_latest_verification_provider_id'
      add_index [:provider_version_id], name: 'ndx_latest_verification_provider_version_id'
    end
  end

  down do
    alter_table(:latest_verification_id_for_pact_version_and_provider_version) do
      drop_index [:consumer_id], name: 'ndx_latest_verification_consumer_id'
      drop_index [:provider_id], name: 'ndx_latest_verification_provider_id'
      drop_index [:provider_version_id], name: 'ndx_latest_verification_provider_version_id'
    end
  end
end
