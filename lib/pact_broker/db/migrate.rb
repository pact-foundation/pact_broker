require "sequel"
Sequel.extension :migration

module PactBroker
  module Db
    class Migrate
      def self.call database_connection, options = {}
        db_migrations_dir = PactBroker::ProjectRoot.path.join("db","migrations")
        PactBroker.logger.info "Running migrations in directory #{db_migrations_dir}, target=#{options.fetch(:target, 'end')}"
        Sequel::TimestampMigrator.new(database_connection, db_migrations_dir, options).run
      end
    end
  end
end
