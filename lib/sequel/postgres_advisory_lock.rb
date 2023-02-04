module Sequel
  class PostgresAdvisoryLock
    def initialize(database_connection, name, type = :pg_try_advisory_lock)
      @database_connection = database_connection
      @name = name
      @type = type
      @lock_obtained = false
    end

    def with_lock
      if postgres?
        @database_connection.extension :pg_advisory_lock
        @database_connection.register_advisory_lock(@name, @type)
        results = @database_connection.with_advisory_lock(@name) do
          @lock_obtained = true
          yield
        end
        results
      else
        @lock_obtained = true
        yield
      end
    end

    def lock_obtained?
      @lock_obtained
    end

    def postgres?
      @database_connection.adapter_scheme.to_s == "postgres"
    end
  end
end
