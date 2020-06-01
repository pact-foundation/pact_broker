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
      attr_accessor :options

      def initialize &block
        @options = {}
        rake_task &block
      end

      def rake_task &block
        namespace :pact_broker do
          namespace :db do
            desc "Run sequel migrations for pact broker database"
            task :migrate, [:target] do | t, args |
              require 'pact_broker/db/migrate'
              require 'pact_broker/db/version'

              instance_eval(&block)

              if args[:target]
                options[:target] = args[:target].to_i
              end

              if (logger = database_connection.loggers.first)
                current_version = PactBroker::DB::Version.call(database_connection)
                if options[:target]
                  logger.info "Migrating from schema version #{current_version} to #{options[:target]}"
                else
                  logger.info "Migrating from schema version #{current_version} to latest"
                end
              end

              PactBroker::DB::Migrate.call(database_connection, options)

              if logger
                current_version = PactBroker::DB::Version.call(database_connection)
                logger.info "Current schema version is now #{current_version}"
              end
            end
          end
        end
      end
    end
  end
end