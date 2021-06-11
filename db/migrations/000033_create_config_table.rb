require_relative "migration_helper"

Sequel.migration do
  change do
    create_table(:config, charset: "utf8") do
      primary_key :id
      String :name, null: false
      String :type, null: false
      String :value, type: PactBroker::MigrationHelper.large_text_type
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:name], unique: true, name: "unq_config_name"
    end
  end
end
