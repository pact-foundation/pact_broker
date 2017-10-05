require 'securerandom'

Sequel.migration do
  up do
    from(:triggered_webhooks).where(webhook_id: nil).each do | triggered_webhook |
      from(:webhook_executions).where(triggered_webhook_id: triggered_webhook[:id]).delete
      from(:triggered_webhooks).where(id: triggered_webhook[:id]).delete
    end

    from(:webhook_executions).where(webhook_id: nil, triggered_webhook_id: nil).delete
  end

  # TODO
  # alter_table(:triggered_webhooks) do
  #  set_column_not_null(:webhook_id)
  # end

  down do
  end
end
