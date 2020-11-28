module PactBroker
  module DB
    class CleanTask < ::Rake::TaskLib

      attr_accessor :database_connection
      attr_reader :keep_version_selectors
      attr_accessor :version_deletion_limit
      attr_accessor :logger

      def initialize &block
        require 'pact_broker/db/clean_incremental'
        @version_deletion_limit = 1000
        @keep_version_selectors = PactBroker::DB::CleanIncremental::DEFAULT_KEEP_SELECTORS
        rake_task &block
      end

      def keep_version_selectors=(keep_version_selectors)
        require 'pact_broker/matrix/unresolved_selector'
        @keep_version_selectors = [*keep_version_selectors].collect do | hash |
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

              raise PactBroker::Error.new("You must specify the version_deletion_limit") unless version_deletion_limit

              if keep_version_selectors.nil? || keep_version_selectors.empty?
                raise PactBroker::Error.new("You must specify which versions to keep")
              else
                output "Deleting oldest #{version_deletion_limit} versions, keeping versions that match the configured selectors", keep_version_selectors
              end

              start_time = Time.now
              results = PactBroker::DB::CleanIncremental.call(
                database_connection, keep: keep_version_selectors, limit: version_deletion_limit, logger: logger)
              end_time = Time.now
              elapsed_seconds = (end_time - start_time).to_i
              output "Results (#{elapsed_seconds} seconds)", results
            end

            def output string, payload = {}
              logger ? logger.info(string, payload: payload) : puts("#{string} #{payload}")
            end
          end
        end
      end
    end
  end
end
