require "pact_broker/project_root"
require "pact_broker/db/migrate"
require "pact_broker/db/version"
require "pact_broker/db"
require "sequel"
require "yaml"
require "pact_broker/db/table_dependency_calculator"
require_relative "connection"

Sequel.extension :migration

module PactBroker
  module TestDatabase

    extend self

    def migrate target = nil
      opts = target ? { target: target } : {}
      PactBroker::DB::Migrate.call(database, opts)
    end

    def version
      PactBroker::DB::Version.call(database)
    end

    def delete_database_file
      FileUtils.rm_rf(database_file_path) if sqlite?
    end

    def ensure_database_dir_exists
      FileUtils.mkdir_p(File.dirname(database_file_path)) if sqlite?
    end

    def drop_objects
      drop_views
      drop_tables
      drop_sequences
    end

    def drop_tables
      ordered_tables.each do | table_name |
        database.drop_table(table_name, cascade: psql?)
      end
      database.drop_table(:schema_migrations) if database.table_exists?(:schema_migrations)
    end

    def drop_views
      database.views.each do | view_name |
        begin
          # checking for existence using table_exists? doesn't work in sqlite
          database.drop_view(view_name, cascade: psql?)
        rescue Sequel::DatabaseError => e
          # Cascade will have deleted some views already with pg
          raise e unless e.cause.class.name == "PG::UndefinedTable"
        end
      end
    end

    def drop_sequences
      if psql?
        database.run("DROP SEQUENCE verification_number_sequence")
        database.run("DROP SEQUENCE version_order_sequence")
      end
    end

    def create
      if psql?
        system('psql postgres -c "create database pact_broker"')
        system('psql postgres -c "CREATE USER pact_broker WITH PASSWORD \'pact_broker\'"')
        system('psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE pact_broker to pact_broker"')
      elsif sqlite?
        ensure_database_dir_exists
      else
        raise "Unknown database adapter #{adapter}"
      end
    end

    def recreate
      drop_tables
      create
    end

    def truncate
      ordered_tables.each do | table_name |
        if database.table_exists?(table_name)
          begin
            database[table_name].delete
          rescue SQLite3::ConstraintException => e
            puts "Could not delete the following records from #{table_name}: #{database[table_name].select_all}"
            raise e
          end
        end
      end
    end

    def database= database
      @@database = database
    end

    def database
      @@database ||= begin
        ::PactBroker::TestDatabase.connection_for_test_database
      end
    end

    private

    def ordered_tables
      PactBroker::DB::TableDependencyCalculator.call(database)
    end

    def psql?
      ::PactBroker::TestDatabase.postgres?
    end

    def sqlite?
      ::PactBroker::TestDatabase.sqlite?
    end

    def migrations_dir
      PactBroker.project_root.join("db","migrations")
    end

    def database_file_path
      ::PactBroker::TestDatabase.configuration_for_test_database["database"]
    end

    def adapter
      ::PactBroker::TestDatabase.configuration_for_test_database["adapter"]
    end
  end
end
