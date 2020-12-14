module Sequel
  module StatementTimeout
    def with_statement_timeout(timeout_seconds = 20)
      # Might not have postgres class loaded, use class name
      if self.class.name == "Sequel::Postgres::Database"
          # Don't want to use a transaction because this will often be a read and a transaction is unnecessary.
          # Also, when using it for clean, want to control the transactions outside this.
          current_statement_timeout = execute("show statement_timeout") { |r| r.first.values.first }
          run("SET statement_timeout = '#{timeout_seconds}s'")
          begin
            yield
          ensure
            run("SET statement_timeout = '#{current_statement_timeout}'")
          end
      else
        yield
      end
    end
  end

  Database.register_extension(:statement_timeout){|db| db.extend(StatementTimeout) }
end
