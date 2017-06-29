require_relative 'db'

raise 'Could not find :schema_migrations table' unless DB.table_exists?(:schema_migrations)
raise 'No migrations files found in schema_migrations' unless DB[:schema_migrations].count > 0

expected_first_migration_filename = '000001_create_pacticipant_table.rb'
first_migration_filename = DB[:schema_migrations].order(:filename).first[:filename]
raise "Expected first migration file name to be #{expected_first_migration_filename} but was #{first_migration_filename}" unless first_migration_filename == expected_first_migration_filename
