

Sequel.migration do
  up do
    alter_table(:verifications) do
      add_index([:provider_version_id], name: "verifications_provider_version_id_index")
    end

  end

  down do
    alter_table(:verifications) do
      drop_index([:provider_version_id], name: "verifications_provider_version_id_index")
    end
  end
end
