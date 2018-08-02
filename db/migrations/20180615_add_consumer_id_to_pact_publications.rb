Sequel.migration do
  change do
    alter_table(:pact_publications) do
      add_foreign_key(:consumer_id, :pacticipants)
      add_index(:consumer_id, name: "pact_publications_consumer_id_index")
    end

    # TODO
    # alter_table(:pact_publications) do
    #   set_column_not_null(:consumer_id)
    # end
  end
end
