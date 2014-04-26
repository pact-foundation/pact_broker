require 'sequel'

module PactBroker
  module DB

    MIGRATIONS_DIR = File.expand_path("../../../db/migrations", __FILE__)

    def self.run_migrations database_connection
      Sequel.extension :migration
      Sequel::Migrator.run(database_connection, PactBroker::DB::MIGRATIONS_DIR)
    end
  end
end