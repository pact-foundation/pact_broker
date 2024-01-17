# This task is used to clean up old data in a Pact Broker database
# to stop performance issues from slowing down responses when there is
# too much data.
# See https://docs.pact.io/pact_broker/administration/maintenance
require "rake/tasklib"

module PactBroker
  module DB
    class CleanTask < ::Rake::TaskLib

      attr_accessor :database_connection
      attr_reader :keep_version_selectors
      attr_accessor :version_deletion_limit
      attr_accessor :logger
      attr_accessor :dry_run
      attr_accessor :use_lock # allow disabling of postgres lock if it is causing problems

      def initialize &block
        require "pact_broker/db/clean_incremental"
        @version_deletion_limit = 1000
        @dry_run = false
        @use_lock = true
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

              with_lock do
                perform_clean
              end
            end
          end
        end
      end

      def perform_clean
        require "pact_broker/db/clean_incremental"
        require "pact_broker/error"
        require "yaml"
        require "benchmark"

        raise PactBroker::Error.new("You must specify the version_deletion_limit") unless version_deletion_limit

        if keep_version_selectors.nil? || keep_version_selectors.empty?
          raise PactBroker::Error.new("You must specify which versions to keep")
        else
          add_defaults_to_keep_selectors
          output "Deleting oldest #{version_deletion_limit} versions, keeping versions that match the configured selectors", keep_version_selectors.collect(&:to_hash)
        end

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

      # Use a Postgres advisory lock to ensure that only one clean can run at a time.
      # This allows a cron schedule to be used on the Pact Broker Docker image when deployed
      # on a multi-instance architecture, without all the instances stepping on each other's toes.
      #
      # Any tasks that attempt to run while a clean job is running will skip the clean
      # and exit with a message and a success code.
      #
      # To test that the lock works, run:
      #   script/docker/db-start.sh
      #   script/docker/db-migrate.sh
      #   for i in {0..3}; do PACT_BROKER_TEST_DATABASE_URL=postgres://postgres:postgres@localhost/postgres bundle exec rake pact_broker:db:clean &;  done;
      #
      # There will be 3 messages saying "Clean was not performed" and output from one thread showing the clean is being done.
      def with_lock
        if use_lock
          require "pact_broker/db/advisory_lock"

          lock = PactBroker::DB::AdvisoryLock.new(database_connection, :clean, :pg_try_advisory_lock)
          results = lock.with_lock do
            yield
          end

          if !lock.lock_obtained?
            output("Clean was not performed as a clean is already in progress. Exiting.")
          end
          results
        else
          yield
        end
      end

      def output(string, payload = {})
        prefix = dry_run ? "[DRY RUN] " : ""
        logger ? logger.info("#{prefix}#{string}", payload) : puts("#{prefix}#{string} #{payload.to_json}")
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
