require 'digest/sha1'
require_relative 'migration_helper'

Sequel.migration do
  up do
    PactBroker::MigrationHelper.with_mysql do
      run("SET FOREIGN_KEY_CHECKS = 0")
    end

    alter_table(:pacts) do
      set_column_not_null(:pact_version_content_sha)
    end

    PactBroker::MigrationHelper.with_mysql do
      run("SET FOREIGN_KEY_CHECKS = 1")
    end
  end
end
