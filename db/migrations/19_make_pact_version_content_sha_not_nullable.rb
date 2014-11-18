require 'digest/sha1'
require_relative 'migration_helper'

Sequel.migration do
  change do
    alter_table(:pacts) do
      set_column_not_null(:pact_version_content_sha)
    end
  end
end
