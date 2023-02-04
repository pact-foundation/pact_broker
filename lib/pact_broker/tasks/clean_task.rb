module PactBroker
  module DB
    class CleanTask < ::Rake::TaskLib

      attr_accessor :database_connection
      attr_reader :keep_version_selectors
      attr_accessor :version_deletion_limit
      attr_accessor :logger
      attr_accessor :dry_run

      def initialize &block
        require "pact_broker/db/clean_incremental"
        @version_deletion_limit = 1000
        @dry_run = false
        @keep_version_selectors = PactBroker::DB::CleanIncremental::DEFAULT_KEEP_SELECTORS
        rake_task(&block)
      end

      def keep_version_selectors=(keep_version_selectors)
        require "pact_broker/db/clean/selector"
        @keep_version_selectors = [*keep_version_selectors].collect do | hash |
          PactBroker::DB::Clean::Selector.from_hash(hash)
        end
      end

      def rake_task &block
        namespace :pact_broker do
          namespace :db do
            desc "Clean unnecessary pacts and verifications from database"
            task :clean do | _t, _args |

              instance_eval(&block)

              require "pact_broker/db/clean_incremental"
              require "pact_broker/error"
              require "yaml"
              require "benchmark"
              require "sequel/postgres_advisory_lock"

              raise PactBroker::Error.new("You must specify the version_deletion_limit") unless version_deletion_limit

              prefix = dry_run ? "[DRY RUN] " : ""

              if keep_version_selectors.nil? || keep_version_selectors.empty?
                raise PactBroker::Error.new("You must specify which versions to keep")
              else
                add_defaults_to_keep_selectors
                output "#{prefix}Deleting oldest #{version_deletion_limit} versions, keeping versions that match the configured selectors", keep_version_selectors.collect(&:to_hash)
              end

              database_lock = Sequel::PostgresAdvisoryLock.new(database_connection, :clean)
              
              database_lock.with_lock do
                execute_clean
              end

              if !database_lock.lock_obtained?
                output "Did not execute clean as another process is currently cleaning"
              end
            end
          end
        end
      end

      def execute_clean
        start_time = Time.now
        results = PactBroker::DB::CleanIncremental.call(database_connection,
          keep: keep_version_selectors,
          limit: version_deletion_limit,
          logger: logger,
          dry_run: dry_run
        )
        end_time = Time.now
        elapsed_seconds = (end_time - start_time).to_i
        output "Results (#{elapsed_seconds} seconds)", results
      end

      def output string, payload = {}
        logger ? logger.info(string, payload) : puts("#{string} #{payload.to_json}")
      end

      def add_defaults_to_keep_selectors
        if keep_version_selectors.none?(&:currently_deployed?)
          selector = PactBroker::DB::Clean::Selector.new(deployed: true)
          output("Automatically adding #{selector.to_hash} to keep version selectors")
          keep_version_selectors << selector
        end

        if keep_version_selectors.none?(&:currently_supported?)
          selector = PactBroker::DB::Clean::Selector.new(released: true)
          output("Automatically adding #{ selector.to_hash } to keep version selectors")
          keep_version_selectors << selector
        end
      end
    end
  end
end
