require 'digest/sha1'
require_relative 'migration_helper'

Sequel.migration do
  up do
    drop_table(:pacts)
  end
end
