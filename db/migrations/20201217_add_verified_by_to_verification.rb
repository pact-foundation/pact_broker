require_relative 'migration_helper'

Sequel.migration do
  change do
    add_column(:verifications, :verified_by_implementation, String)
    add_column(:verifications, :verified_by_version, String)
  end
end
