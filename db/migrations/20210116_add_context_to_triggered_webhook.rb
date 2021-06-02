require_relative "migration_helper"

include PactBroker::MigrationHelper

Sequel.migration do
  change do
    alter_table(:triggered_webhooks) do
      add_column(:event_context, String)
    end
  end
end
