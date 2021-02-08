require_relative 'migration_helper'

include PactBroker::MigrationHelper

Sequel.migration do
  up do
    if !mysql?
      alter_table(:webhook_executions) do
        add_index([:triggered_webhook_id], name: "webhook_executions_triggered_webhook_id_index")
      end
      # MySQL automatically creates indexes for foreign keys then complains if you
      # re-create it with a different name and try to drop it.

      # https://stackoverflow.com/a/52274628/832671 - "When there is only one index that can be used
      # for the foreign key, it can't be dropped. If you really wan't to drop it, you either have to drop
      # the foreign key constraint or to create another index for it first."

      alter_table(:triggered_webhooks) do
        add_index([:webhook_id], name: "triggered_webhooks_webhook_id_index")
        add_index([:consumer_id], name: "triggered_webhooks_consumer_id_index")
        add_index([:provider_id], name: "triggered_webhooks_provider_id_index")
        add_index([:verification_id], name: "triggered_webhooks_verification_id_index")
        add_index([:pact_publication_id], name: "triggered_webhooks_pact_publication_id_index")
      end
    end
  end

  down do
    if !mysql?
      alter_table(:webhook_executions) do
        drop_index([:triggered_webhook_id], name: "webhook_executions_triggered_webhook_id_index")
      end
      # MySQL automatically creates indexes for foreign keys then complains if you
      # re-create it with a different name and try to drop it.

      # https://stackoverflow.com/a/52274628/832671 - "When there is only one index that can be used
      # for the foreign key, it can't be dropped. If you really wan't to drop it, you either have to drop
      # the foreign key constraint or to create another index for it first."

      alter_table(:triggered_webhooks) do
        drop_index([:webhook_id], name: "triggered_webhooks_webhook_id_index")
        drop_index([:consumer_id], name: "triggered_webhooks_consumer_id_index")
        drop_index([:provider_id], name: "triggered_webhooks_provider_id_index")
        drop_index([:verification_id], name: "triggered_webhooks_verification_id_index")
        drop_index([:pact_publication_id], name: "triggered_webhooks_pact_publication_id_index")
      end
    end
  end
end
