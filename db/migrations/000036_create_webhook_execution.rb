require_relative "migration_helper"

Sequel.migration do
  change do
    create_table(:webhook_executions, charset: "utf8") do
      primary_key :id
      foreign_key :webhook_id, :webhooks
      foreign_key :pact_publication_id, :pact_publications
      foreign_key :consumer_id, :pacticipants, null: false
      foreign_key :provider_id, :pacticipants, null: false
      Boolean :success, null: false
      String :logs, type: PactBroker::MigrationHelper.large_text_type
      DateTime :created_at, null: false
    end
  end
end
