require_relative 'migration_helper'

Sequel.migration do
  up do
    if PactBroker::MigrationHelper.postgres?
      row = from(:verification_sequence_number).select(:value).limit(1).first
      start = row ? row[:value] + 100 : 1
      run("CREATE SEQUENCE verification_number_sequence START WITH #{start}")
    end
  end

  down do
    if PactBroker::MigrationHelper.postgres?
      nextval = execute("SELECT nextval('verification_number_sequence') as val") { |v| v.first["val"].to_i }
      # Add a safety margin!
      from(:verification_sequence_number).update(value: nextval + 100)
      run("DROP SEQUENCE verification_number_sequence")
    end
  end
end
