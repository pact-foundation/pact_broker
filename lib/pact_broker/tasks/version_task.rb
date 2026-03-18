require "rake/tasklib"

=begin

require 'pact_broker/tasks'

PactBroker::Db::VersionTask.new do | task |
  require 'my_app/db'
  task.database_connection = MyApp::DB
end

=end

module PactBroker
  module Db
    class VersionTask < ::Rake::TaskLib

      attr_accessor :database_connection

      def initialize &block
        rake_task(&block)
      end

      def rake_task &block
        namespace :pact_broker do
          namespace :db do
            desc "Display the current database migration version"
            task :version do
              instance_eval(&block)
              puts PactBroker::Db::Version.call(database_connection)
            end
          end
        end
      end
    end
  end
end
