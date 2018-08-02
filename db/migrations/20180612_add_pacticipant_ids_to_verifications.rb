Sequel.migration do
  change do
    alter_table(:verifications) do
      add_foreign_key(:consumer_id, :pacticipants)
      add_foreign_key(:provider_id, :pacticipants)
      add_index(:consumer_id, name: "verifications_consumer_id_index")
      add_index(:provider_id, name: "verifications_provider_id_index")
      add_index([:provider_id, :consumer_id], name: "verifications_provider_id_consumer_id_index")
    end

    # TODO
    # alter_table(:verifications) do
    #   set_column_not_null(:consumer_id)
    #   set_column_not_null(:provider_id)
    # end
  end
end
