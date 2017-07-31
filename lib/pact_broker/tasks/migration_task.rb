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
            task :migrate, [:target] do | t, args |
              require 'pact_broker/db/migrate'
              instance_eval(&block)
              options = {}
              if args[:target]
                options[:target] = args[:target].to_i
              end
              PactBroker::DB::Migrate.call(database_connection, options)
            end
          end
        end
      end
    end
  end
end