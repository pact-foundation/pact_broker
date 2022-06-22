require_relative "migration_helper"
include PactBroker::MigrationHelper

Sequel.migration do
  up do
    # Need to do this again because didn't actually set default of allow_dangerous_contract_modification to true
    # when the first migration was run in db/migrations/20210810_set_allow_contract_modification.rb
    for_upgrades_of_existing_installations do
      from(:config).insert_ignore.insert(
        name: "allow_dangerous_contract_modification",
        type: "boolean",
        value: "1",
        created_at: Sequel.datetime_class.now,
        updated_at: Sequel.datetime_class.now
      )
    end
  end

  down do

  end
end
