require 'rake/tasklib'

=begin

require 'pact_broker/tasks'

PactBroker::DB::DataMigrationTask.new do | task |
  require 'my_app/db'
  task.database_connection = MyApp::DB
end

=end

module PactBroker
  module DB
    class DataMigrationTask < ::Rake::TaskLib

      attr_accessor :database_connection

      def initialize &block
        rake_task(&block)
      end

      def rake_task &block
        namespace :pact_broker do
          namespace :db do
            desc "Run data migrations for pact broker database"
            task :migrate_data do | _t, _args |
              require 'pact_broker/db'
              instance_eval(&block)
              PactBroker::DB.run_data_migrations database_connection
            end
          end
        end
      end
    end
  end
end
