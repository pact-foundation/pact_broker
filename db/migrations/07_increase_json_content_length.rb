require_relative 'migration_helper'

Sequel.migration do
  change do
    alter_table(:pacts) do
      set_column_type(:json_content, PactBroker::MigrationHelper.large_text_type)
    end
  end
end
