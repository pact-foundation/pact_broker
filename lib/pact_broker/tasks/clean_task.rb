module PactBroker
  module DB
    class CleanTask < ::Rake::TaskLib

      attr_accessor :database_connection
      attr_reader :keep
      attr_accessor :limit

      def initialize &block
        require 'pact_broker/db/clean_incremental'
        @limit = 1000
        @keep = PactBroker::DB::CleanIncremental::DEFAULT_KEEP_SELECTORS
        rake_task &block
      end

      def keep=(keep)
        require 'pact_broker/matrix/unresolved_selector'
        @keep = [*keep].collect do | hash |
          PactBroker::Matrix::UnresolvedSelector.from_hash(hash)
        end
      end

      def rake_task &block
        namespace :pact_broker do
          namespace :db do
            desc "Clean unnecessary pacts and verifications from database"
            task :clean do | t, args |

              instance_eval(&block)

              require 'pact_broker/db/clean_incremental'
              require 'pact_broker/error'
              require 'yaml'
              require 'benchmark'

              raise PactBroker::Error.new("You must specify a limit for the number of versions to delete") unless limit

              if keep.nil? || keep.empty?
                raise PactBroker::Error.new("You must specify which versions to keep")
              else
                puts "Deleting oldest #{limit} versions, keeping versions that match the following selectors: #{keep}..."
              end

              start_time = Time.now
              results = PactBroker::DB::CleanIncremental.call(database_connection, keep: keep, limit: limit)
              end_time = Time.now
              elapsed_seconds = (end_time - start_time).to_i
              puts results.to_yaml.gsub("---", "\nResults (#{elapsed_seconds} seconds)\n-------")
            end
          end
        end
      end
    end
  end
end
