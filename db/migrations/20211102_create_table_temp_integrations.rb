Sequel.migration do
  up do
    create_table(:temp_integrations, charset: "utf8") do
      primary_key :id
      foreign_key(:consumer_id, :pacticipants, null: false, on_delete: :cascade, foreign_key_constraint_name: "integrations_consumer_id_foreign_key")
      foreign_key(:provider_id, :pacticipants, null: false, on_delete: :cascade, foreign_key_constraint_name: "integrations_provider_id_foreign_key")
      String :consumer_name
      String :provider_name
    end

    # TODO drop these columns
    # They are just for backwards compatiblity during schema migrations
    # alter_table(:integrations) do
    #   drop_column(:consumer_name)
    #   drop_column(:provider_name)
    # end
  end

  down do
    drop_table(:temp_integrations)
  end
end
