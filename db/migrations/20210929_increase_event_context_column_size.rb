require_relative "migration_helper"
include PactBroker::MigrationHelper

Sequel.migration do
  up do
    if mysql?
      run("ALTER TABLE triggered_webhooks CHANGE event_context event_context mediumtext")
    end
  end

  down do

  end
end
