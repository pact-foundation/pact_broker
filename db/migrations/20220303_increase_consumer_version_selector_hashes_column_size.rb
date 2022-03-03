require_relative "migration_helper"
include PactBroker::MigrationHelper

Sequel.migration do
  up do
    if mysql?
      run("ALTER TABLE verifications CHANGE consumer_version_selector_hashes consumer_version_selector_hashes mediumtext")
    end
  end

  down do

  end
end
