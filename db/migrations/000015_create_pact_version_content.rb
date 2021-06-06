require "digest/sha1"
require_relative "migration_helper"

Sequel.migration do
  change do
    create_table(:pact_version_contents, charset: "utf8") do
      String :sha, primary_key: true, null: false, primary_key_constraint_name: "pk_pact_version_contents"
      String :content, type: PactBroker::MigrationHelper.large_text_type
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
