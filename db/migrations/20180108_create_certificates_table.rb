require_relative "migration_helper"

Sequel.migration do
  change do
    create_table(:certificates, charset: "utf8") do
      primary_key :id
      String :uuid, null: false, unique: true, unique_constraint_name: "uq_certificate_uuid"
      String :description, null: true
      column :content, PactBroker::MigrationHelper.large_text_type, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
