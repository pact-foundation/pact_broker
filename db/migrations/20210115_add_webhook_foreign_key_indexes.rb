require_relative 'migration_helper'

include PactBroker::MigrationHelper

Sequel.migration do
  change do
    alter_table(:webhook_executions) do
      add_index([:triggered_webhook_id], name: "webhook_executions_triggered_webhook_id_index")
    end

    alter_table(:triggered_webhooks) do
      add_index([:webhook_id], name: "triggered_webhooks_webhook_id_index")
      add_index([:consumer_id], name: "triggered_webhooks_consumer_id_index")
      add_index([:provider_id], name: "triggered_webhooks_provider_id_index")
      add_index([:pact_publication_id], name: "triggered_webhooks_pact_publication_id_index")
      add_index([:verification_id], name: "triggered_webhooks_verification_id_index")
    end
  end
end
