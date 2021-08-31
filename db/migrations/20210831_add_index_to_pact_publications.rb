Sequel.migration do
  change do
    alter_table(:pact_publications) do
      add_index [:consumer_id, :provider_id, :consumer_version_order], name: :pact_publications_cid_pid_cvo_index
    end
  end
end
