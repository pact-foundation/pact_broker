require "pact_broker/db"

module MatrixBaseline
  # Runs the adapter-appropriate EXPLAIN for a SQL string and returns the plan
  # as text. Postgres gives full plans with row estimates, costs, buffer counts
  # and sort/hash memory usage; SQLite gives EXPLAIN QUERY PLAN (scan/index
  # shape only) and is used by the test suite. Postgres and SQLite are the only
  # supported backends.
  #
  # Wall-clock measurements are deliberately excluded so two runs of unchanged
  # code produce an identical plan. `TIMING OFF` drops the per-node
  # `actual time=` figures, and the trailing `Planning Time` / `Execution Time`
  # summary lines are stripped. What remains — costs, actual row counts, buffer
  # hit/read/dirtied counts, memory usage — describes the work the query does
  # rather than how fast this machine happened to do it.
  class Explain
    WALL_CLOCK_SUMMARY = /\A\s*(Planning|Execution) Time:/.freeze

    def self.call(sql, db: PactBroker::DB.connection)
      case db.adapter_scheme.to_s
      when /postgres/
        rows = db["EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, FORMAT TEXT) #{sql}"].all
        strip_wall_clock(rows.map { |r| r.values.first })
      when /sqlite/
        rows = db["EXPLAIN QUERY PLAN #{sql}"].all
        rows.map { |r| r.values.map(&:to_s).join(" | ") }.join("\n")
      else
        raise ArgumentError, "unsupported adapter for EXPLAIN: #{db.adapter_scheme}"
      end
    end

    def self.strip_wall_clock(lines)
      lines.reject { |line| line.to_s =~ WALL_CLOCK_SUMMARY }.join("\n")
    end
    private_class_method :strip_wall_clock
  end
end
