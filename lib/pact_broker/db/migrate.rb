require 'sequel'
require 'pact_broker/project_root'
Sequel.extension :migration

module PactBroker
  module DB
    class Migrate
      def self.call database_connection, options = {}
        db_migrations_dir = PactBroker.project_root.join('db','migrations')
        puts "Running migrations in directory #{db_migrations_dir}, target=#{options.fetch(:target, 'end')}"
        Sequel::TimestampMigrator.new(database_connection, db_migrations_dir, options).run
      end
    end
  end
end
