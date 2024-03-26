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
# Docs on lock types from From https://www.postgresql.org/docs/9.1/functions-admin.html
#
# pg_advisory_lock locks an application-defined resource.
# If another session already holds a lock on the same resource identifier, this function will wait until the
# resource becomes available.
# The lock is exclusive.
# Multiple lock requests stack, so that if the same resource is locked three times it must then be unlocked three
# times to be released for other sessions' use.

# pg_advisory_lock_shared works the same as pg_advisory_lock, except the lock can be shared with other sessions
# requesting shared locks. Only would-be exclusive lockers are locked out.

# pg_try_advisory_lock is similar to pg_advisory_lock, except the function will not wait for the lock to become available.
# It will either obtain the lock immediately and return true, or return false if the lock cannot be acquired immediately.

# There are race conditions with the in-memory lock registry that may cause problems when running multiple threads.
# To handle this, the code catches and ignores the error Sequel::Postgres::PgAdvisoryLock::LockAlreadyRegistered

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
