require 'sequel'

module PactBroker
  module DB

    MIGRATIONS_DIR = File.expand_path("../../../db/migrations", __FILE__)

    def self.connection= connection
      @@connection = connection
    end

    def self.connection
      @@connection
    end

    def self.run_migrations
      Sequel.extension :migration
      Sequel::Migrator.run(connection, PactBroker::DB::MIGRATIONS_DIR)
    end
  end
end