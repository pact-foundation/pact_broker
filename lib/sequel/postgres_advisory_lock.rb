require "pact_broker/logging"

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

module Sequel
  class PostgresAdvisoryLock
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
        logger.debug("Executing without lock as this is not a postgres database")
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
      unless @database_connection.registered_advisory_locks.key?(@name)
        logger.debug("Registering postgres lock of type #{@type} with name #{@name}")
        begin
          @database_connection.register_advisory_lock(@name, @type)
        rescue Sequel::Error => e
          logger.info(e.message)
        end
      end
    end
  end
end
