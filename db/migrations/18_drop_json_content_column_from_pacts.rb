require 'digest/sha1'
require_relative 'migration_helper'

Sequel.migration do
  change do
    alter_table(:pacts) do
      drop_column(:json_content)
    end
  end
end
