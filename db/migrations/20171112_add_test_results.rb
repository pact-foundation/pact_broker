require_relative "migration_helper"

Sequel.migration do
  change do
    add_column(:verifications, :test_results, PactBroker::MigrationHelper.large_text_type)
  end
end
