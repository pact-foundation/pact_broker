# Copied with thanks from https://github.com/yuryroot/sequel-pg_advisory_lock/blob/d7509aa/lib/sequel/extensions/pg_advisory_lock.rb
# The reason this is copy/pasted and modified is that I wanted to allow exact duplicate
# locks to be registered because different threads running the same code
# should not cause a Sequel::Error to be raised.
# Also, I wanted it to use Concurrent::Hash for multi-threaded environments.
# Made minor change in begin ensure block in with_advisory_lock method.

require "sequel"
require "zlib"
require "concurrent/hash"

module Sequel
  module Postgres
    module PgAdvisoryLock

      SESSION_LEVEL_LOCKS = [
        :pg_advisory_lock,
        :pg_try_advisory_lock
      ].freeze

      TRANSACTION_LEVEL_LOCKS = [
        :pg_advisory_xact_lock,
        :pg_try_advisory_xact_lock
      ].freeze

      LOCK_FUNCTIONS = (SESSION_LEVEL_LOCKS + TRANSACTION_LEVEL_LOCKS).freeze

      DEFAULT_LOCK_FUNCTION = :pg_advisory_lock
      UNLOCK_FUNCTION = :pg_advisory_unlock

      class LockAlreadyRegistered < Sequel::Error; end

      def registered_advisory_locks
        @registered_advisory_locks ||= Concurrent::Hash.new
      end

      def with_advisory_lock(name, id = nil)
        options = registered_advisory_locks.fetch(name.to_sym)

        lock_key = options.fetch(:key)
        function_params = [lock_key, id].compact

        lock_function = options.fetch(:lock_function)
        transaction_level_lock = TRANSACTION_LEVEL_LOCKS.include?(lock_function)

        if transaction_level_lock
          # TODO: It's allowed to specify additional options (in particular, :server)
          #       while opening database transaction.
          #       That's why this check must be smarter.
          unless in_transaction?
            raise Error, "Transaction must be manually opened before using transaction level lock '#{lock_function}'"
          end

          if get(Sequel.function(lock_function, *function_params))
            yield
          end
        else
          synchronize do
            if get(Sequel.function(lock_function, *function_params))
              begin
                yield
              ensure
                get(Sequel.function(UNLOCK_FUNCTION, *function_params))
              end
            end
          end
        end
      end

      # Beth: not sure how much extra value this registration provides.
      # It turns the name into a number, and makes sure the name/number is unique,
      # and that you don't try and use a different lock function with the same name.
      def register_advisory_lock(name, lock_function = DEFAULT_LOCK_FUNCTION)
        name = name.to_sym

        if registered_advisory_locks.key?(name) && registered_advisory_locks[name][:lock_function] != lock_function
          raise LockAlreadyRegistered, "Lock with name :#{name} is already registered with a different lock function (#{registered_advisory_locks[name][:lock_function]})"
        end

        key = advisory_lock_key_for(name)
        name_for_key = registered_advisory_locks.keys.find { |n| registered_advisory_locks[n].fetch(:key) == key }
        if name_for_key && name_for_key != name
          raise Error, "Lock key #{key} is already taken"
        end

        function = lock_function.to_sym
        unless LOCK_FUNCTIONS.include?(function)
          raise Error, "Invalid lock function :#{function}"
        end

        registered_advisory_locks[name] = { key: key, lock_function: function }
      end

      def advisory_lock_key_for(lock_name)
        Zlib.crc32(lock_name.to_s) % 2 ** 31
      end
    end
  end

  Database.register_extension(:pg_advisory_lock, Postgres::PgAdvisoryLock)
end
