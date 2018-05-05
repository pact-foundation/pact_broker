Sequel.migration do
  change do
    alter_table(:pact_versions) do
      add_column(:verifiable_content_sha, String)
      add_index([:verifiable_content_sha, :provider_id, :consumer_id], name: 'ndx_pact_ver_sha_prov_con')
    end
  end
end
