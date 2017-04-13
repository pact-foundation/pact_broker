require_relative 'migration_helper'

Sequel.migration do
  up do
    create_table(:pact_versions, charset: 'utf8') do
      primary_key :id
      String :sha, null: false, primary_key_constraint_name: 'pk_pact_version'
      String :content, type: PactBroker::MigrationHelper.large_text_type
      DateTime :created_at, null: false
    end
  end

  down do
    drop_table(:pact_versions)
  end
end
