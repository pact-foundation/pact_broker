require 'rake/tasklib'

=begin

require 'pact_broker/tasks'

PactBroker::DB::MigrationTask.new do | task |
  require 'my_app/db'
  task.database_connection = MyApp::DB
end

=end

module PactBroker
  module DB
    class MigrationTask < ::Rake::TaskLib

      attr_accessor :database_connection

      def initialize &block
        rake_task &block
      end

      def rake_task &block
        namespace :pact_broker do
          namespace :db do
            desc "Run sequel migrations for pact broker database"
            task :migrate do
              instance_eval(&block)
              require 'sequel'
              Sequel.extension :migration
              db_migrations_dir = File.expand_path("../../../../db/migrations", __FILE__)
              puts "Running migrations in directory #{db_migrations_dir}"
              Sequel::Migrator.run(database_connection, db_migrations_dir)
            end
          end
        end
      end
    end
  end
end