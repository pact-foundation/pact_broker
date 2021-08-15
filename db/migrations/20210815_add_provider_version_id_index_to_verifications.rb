Sequel.migration do
  change do
    alter_table(:verifications) do
      add_index([:pact_version_id, :id], name: "verifications_pact_version_id_id_index")
    end
  end
end
