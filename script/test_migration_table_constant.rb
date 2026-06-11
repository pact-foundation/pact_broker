#!/usr/bin/env ruby
# Tests that PactBroker::DB::MIGRATION_TABLE is defined and that run_migrations
# respects a custom table: option, using a real postgres database.
#
# Usage: DATABASE_URL=postgres://postgres:postgres@localhost:5438/pact_broker_dev bundle exec ruby script/test_migration_table_constant.rb

require "sequel"
require_relative "../lib/pact_broker/db"

DATABASE_URL = ENV.fetch("DATABASE_URL", "postgres://postgres:postgres@localhost:5438/pact_broker_dev")

db = Sequel.connect(DATABASE_URL)

puts "=== pact_broker migration table constant ==="
puts "MIGRATIONS_DIR : #{PactBroker::DB::MIGRATIONS_DIR}"
puts "MIGRATION_TABLE: #{PactBroker::DB::MIGRATION_TABLE.inspect}"

puts "\n--- Running migrations with custom table :test_pact_broker_schema_migrations ---"
PactBroker::DB.run_migrations(db, table: :test_pact_broker_schema_migrations)

count = db[:test_pact_broker_schema_migrations].count
puts "Migrations applied: #{count}"
raise "Expected > 0 migrations recorded" unless count > 0

puts "is_current? with custom table: #{PactBroker::DB.is_current?(db, table: :test_pact_broker_schema_migrations)}"

db.drop_table(:test_pact_broker_schema_migrations)
puts "\n=== PASS ==="
