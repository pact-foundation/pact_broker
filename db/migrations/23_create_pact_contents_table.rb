require_relative 'migration_helper'

Sequel.migration do
  up do
    create_table(:pact_contents, charset: 'utf8') do
      primary_key :id
      String :sha, null: false, unique: true, unique_constraint_name: 'unq_pvc_sha'
      String :content, type: PactBroker::MigrationHelper.large_text_type
      DateTime :created_at, null: false
    end
  end

  down do
    drop_table(:pact_contents)
  end
end
