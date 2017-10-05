Sequel.migration do
  change do
    alter_table(:webhook_executions) do
      add_foreign_key :triggered_webhook_id, :triggered_webhooks
      set_column_allow_null(:webhook_id)
      set_column_allow_null(:pact_publication_id)
      set_column_allow_null(:consumer_id)
      set_column_allow_null(:provider_id)
    end

    # Hope old code doesn't insert another webhook in the meantime!

    # TODO drop_column(:webhook_executions, :webhook_id)
    # TODO drop_column(:webhook_executions, :webhook_uuid)
    # TODO drop_column(:webhook_executions, :pact_publication_id)
    # TODO drop_column(:webhook_executions, :consumer_id)
    # TODO drop_column(:webhook_executions, :provider_id)

    # TODO
    # alter_table(:webhook_executions) do
    #  set_column_not_null(:triggered_webhook_id)
    # end
  end
end
