require_relative 'migration_helper'

Sequel.migration do
  up do
    if PactBroker::MigrationHelper.postgres?
      row = from(:version_sequence_number).select(:value).limit(1).first
      start = row ? row[:value] + 100 : 1
      run("CREATE SEQUENCE version_order_sequence START WITH #{start}")
    end
  end

  down do
    if PactBroker::MigrationHelper.postgres?
      nextval = execute("SELECT nextval('version_order_sequence') as val") { |v| v.first["val"].to_i }
      # Add a safety margin!
      from(:version_sequence_number).update(value: nextval + 100)
      run("DROP SEQUENCE version_order_sequence")
    end
  end
end
