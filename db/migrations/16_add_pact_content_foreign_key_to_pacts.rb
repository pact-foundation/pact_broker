require 'digest/sha1'
require_relative 'migration_helper'

Sequel.migration do
  change do
    alter_table(:pacts) do
      add_foreign_key :pact_version_content_sha, :pact_version_contents, type: String, null: true, foreign_key_constraint_name: 'fk_pact_version_content'
    end
  end
end
