require "pact_broker/db"

module MatrixBaseline
  # Runs the adapter-appropriate EXPLAIN for a SQL string and returns the plan
  # as text. Postgres gives full plans with row estimates, costs and buffers
  # (EXPLAIN ANALYZE); SQLite gives EXPLAIN QUERY PLAN (scan/index shape only)
  # and is used by the test suite. Postgres and SQLite are the only supported
  # backends.
  class Explain
    def self.call(sql, db: PactBroker::DB.connection)
      case db.adapter_scheme.to_s
      when /postgres/
        rows = db["EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) #{sql}"].all
        rows.map { |r| r.values.first }.join("\n")
      when /sqlite/
        rows = db["EXPLAIN QUERY PLAN #{sql}"].all
        rows.map { |r| r.values.map(&:to_s).join(" | ") }.join("\n")
      else
        raise ArgumentError, "unsupported adapter for EXPLAIN: #{db.adapter_scheme}"
      end
    end
  end
end
