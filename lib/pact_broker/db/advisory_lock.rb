require "pact_broker/logging"

# Uses a Postgres advisory lock to ensure that a given block of code can only have ONE
# thread in excution at a time against a given database.
# When the database is not Postgres, the block will yield without any locks, allowing
# this class to be used safely with other database types, but without the locking
# functionality.
#
# This is a wrapper around the actual implementation code in the Sequel extension from https://github.com/yuryroot/sequel-pg_advisory_lock
# which was copied into this codebase and modified for usage in this codebase.
#
# See https://www.postgresql.org/docs/16/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS for docs on lock types
#

module PactBroker
  module DB
    class AdvisoryLock
      include PactBroker::Logging

      def initialize(database_connection, name, type = :pg_try_advisory_lock)
        @database_connection = database_connection
        @name = name
        @type = type
        @lock_obtained = false
        register_advisory_lock if postgres?
      end

      def with_lock
        if postgres?
          @database_connection.with_advisory_lock(@name) do
            logger.debug("Lock #{@name} obtained")
            @lock_obtained = true
            yield
          end
        else
          logger.warn("Executing block without lock as this is not a Postgres database")
          @lock_obtained = true
          yield
        end
      end

      def lock_obtained?
        @lock_obtained
      end

      private

      def postgres?
        @database_connection.adapter_scheme.to_s =~ /postgres/
      end

      def register_advisory_lock
        @database_connection.extension :pg_advisory_lock
        @database_connection.register_advisory_lock(@name, @type)
      end
    end
  end
end
