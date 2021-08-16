Sequel.migration do
  change do
    alter_table(:pact_publications) do
      add_index [:consumer_id, :consumer_version_order], name: :pact_publications_consumer_id_consumer_version_order
    end
  end
end
