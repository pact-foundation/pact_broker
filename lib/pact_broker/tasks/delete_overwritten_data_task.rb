module PactBroker
  module DB
    class DeleteOverwrittenDataTask < ::Rake::TaskLib
      attr_accessor :database_connection
      attr_accessor :max_age
      attr_accessor :logger
      attr_accessor :deletion_limit
      attr_accessor :dry_run

      def initialize &block
        @max_age = 7
        rake_task(&block)
      end

      def rake_task &block
        namespace :pact_broker do
          namespace :db do
            desc "Delete overwritten pacts and verifications from database"
            task :delete_overwritten_data do | _t, _args |
              require "pact_broker/db/delete_overwritten_data"
              require "yaml"
              require "sequel/postgres_advisory_lock"

              instance_eval(&block)
              options = {}

              prefix = dry_run ? "[DRY RUN] " : ""

              if max_age
                options[:max_age] = max_age
                output "#{prefix}Deleting overwritten pact publications and verifications older than #{max_age} days"
              else
                output "#{prefix}Deleting overwritten pact publications and verifications"
              end

              options[:limit] = deletion_limit if deletion_limit
              options[:dry_run] = dry_run

              database_lock = Sequel::PostgresAdvisoryLock.new(database_connection, :clean)

              database_lock.with_lock do
                execute_delete(options)
              end

              if !database_lock.lock_obtained?
                output "Did not execute deletion of overwritten data as another process is currently deleting"
              end
            end
          end
        end
      end

      def execute_delete(options)
        start_time = Time.now
        results = PactBroker::DB::DeleteOverwrittenData.call(database_connection, options)
        end_time = Time.now
        elapsed_seconds = (end_time - start_time).to_i
        output "Results (#{elapsed_seconds} seconds)", results
      end

      def output string, payload = {}
        logger ? logger.info(string, payload) : puts("#{string} #{payload.to_json}")
      end
    end
  end
end
