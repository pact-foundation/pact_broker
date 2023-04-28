Sequel.migration do
  up do
    if !mysql?
      alter_table(:webhook_executions) do
        add_index([:pact_publication_id], name: "webhook_executions_pact_publication_id_index")
      end
    end
  end

  down do
    if !mysql?
      alter_table(:webhook_executions) do
        drop_index([:pact_publication_id], name: "webhook_executions_pact_publication_id_index")
      end
    end
  end
end
