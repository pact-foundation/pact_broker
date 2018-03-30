module PactBroker
  module DB
    class CleanTask < ::Rake::TaskLib

      attr_accessor :database_connection

      def initialize &block
        rake_task &block
      end

      def rake_task &block
        namespace :pact_broker do
          namespace :db do
            desc "Clean unused pacts and verifications from database"
            task :clean do | t, args |
              require 'pact_broker/db/clean'
              instance_eval(&block)
              PactBroker::DB::Clean.call(database_connection)
            end
          end
        end
      end
    end
  end
end