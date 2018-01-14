require 'sequel'
require 'pact_broker/db/validate_encoding'

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

    def self.run_migrations database_connection
      Sequel.extension :migration
      options = { allow_missing_migration_files: true }
      Sequel::TimestampMigrator.new(database_connection, PactBroker::DB::MIGRATIONS_DIR, options).run
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
