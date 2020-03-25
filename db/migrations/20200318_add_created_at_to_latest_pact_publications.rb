Sequel.migration do
  change do
    # TODO
    # alter_table(:latest_pact_publication_ids_for_consumer_versions) do
    #   set_column_not_null(:created_at)
    # end
    add_column(:latest_pact_publication_ids_for_consumer_versions, :created_at, DateTime)
  end
end
