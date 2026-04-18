require "sequel"

Sequel.datetime_class = DateTime

module PactBroker
  module Db
    MIGRATIONS_DIR = File.expand_path("../../../db/migrations", __FILE__)

    def self.connection= connection
      @connection = connection
    end

    def self.connection
      @connection
    end

    def self.run_migrations database_connection, options = {}
      Sequel.extension :migration
      Sequel::TimestampMigrator.new(database_connection, PactBroker::Db::MIGRATIONS_DIR, options).run
    end

    def self.run_data_migrations database_connection
      PactBroker::Db::MigrateData.(database_connection)
    end

    def self.is_current? database_connection, options = {}
      Sequel.extension :migration
      Sequel::TimestampMigrator.is_current?(database_connection, PactBroker::Db::MIGRATIONS_DIR, options)
    end

    def self.check_current database_connection, options = {}
      Sequel.extension :migration
      Sequel::TimestampMigrator.check_current(database_connection, PactBroker::Db::MIGRATIONS_DIR, options)
    end

    def self.truncate database_connection, options = {}
      exceptions = options[:except] || []
      TableDependencyCalculator.call(database_connection).each do | table_name |
        if !exceptions.include?(table_name)
          begin
            database_connection[table_name].truncate
          rescue StandardError => _ex
            puts "Could not truncate table #{table_name}"
          end
        end
      end
    end

    def self.version database_connection
      PactBroker::Db::Version.call(database_connection)
    end

    def self.validate_connection_config
      PactBroker::Db::ValidateEncoding.(connection)
    end

    def self.set_mysql_strict_mode_if_mysql
      connection.run("SET sql_mode='STRICT_TRANS_TABLES';") if mysql?
    end

    def self.mysql?
      connection.adapter_scheme =~ /mysql/
    end
  end
end
