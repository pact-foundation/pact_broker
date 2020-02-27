module PactBroker
  module DB
    class DeleteOverwrittenDataTask < ::Rake::TaskLib
      attr_accessor :database_connection
      attr_accessor :age_in_days

      def initialize &block
        rake_task &block
      end

      def rake_task &block
        namespace :pact_broker do
          namespace :db do
            desc "Delete overwritten pacts and verifications from database"
            task :delete_overwritten_data do | t, args |
              require 'pact_broker/db/delete_overwritten_data'
              require 'yaml'

              instance_eval(&block)
              options = {}

              if age_in_days
                options[:before] = (Date.today - age_in_days.to_i).to_datetime
                $stdout.puts "Deleting overwritten pact publications and verifications older than #{age_in_days} days"
              else
                $stdout.puts "Deleting overwritten pact publications and verifications"
              end

              report = PactBroker::DB::DeleteOverwrittenData.call(database_connection, options)
              $stdout.puts report.to_yaml
            end
          end
        end
      end
    end
  end
end
