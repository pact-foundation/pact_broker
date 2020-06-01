require 'sequel'
require 'pact_broker/db/validate_encoding'
require 'pact_broker/db/migrate'
require 'pact_broker/db/migrate_data'
require 'pact_broker/db/version'

Sequel.datetime_class = DateTime

module PactBroker
  module DB
    MIGRATIONS_DIR = File.expand_path("../../../db/migrations", __FILE__)

    def self.connection= connection
      @connection = connection
    end

    def self.connection
      @connection
    end

    def self.run_migrations database_connection, options = {}
      Sequel.extension :migration
      Sequel::TimestampMigrator.new(database_connection, PactBroker::DB::MIGRATIONS_DIR, options).run
    end

    def self.run_data_migrations database_connection
      PactBroker::DB::MigrateData.(database_connection)
    end

    def self.is_current? database_connection, options = {}
      Sequel::TimestampMigrator.is_current?(database_connection, PactBroker::DB::MIGRATIONS_DIR, options)
    end

    def self.version database_connection
      PactBroker::DB::Version.call(database_connection)
    end

    def self.validate_connection_config
      PactBroker::DB::ValidateEncoding.(connection)
    end

    def self.set_mysql_strict_mode_if_mysql
      connection.run("SET sql_mode='STRICT_TRANS_TABLES';") if mysql?
    end

    def self.mysql?
      connection.adapter_scheme =~ /mysql/
    end
  end
end
