require "pact_broker/db"
require "pact_broker/db/table_dependency_calculator"

module MatrixBaseline
  # Puts the database into the same physical state before every run, so that
  # two baselines of unchanged code are byte-identical and a diff shows only
  # what the query engine actually did differently.
  #
  # Three things otherwise drift between runs:
  #
  # * Surrogate keys. The suite's usual cleanup deletes rows rather than
  #   truncating, and a rollback does not rewind a sequence, so each run's ids
  #   start where the last one stopped. Those ids are embedded as literals in
  #   the captured SQL, so every statement in the file changes.
  # * Table bloat. Deleted and rolled-back rows leave dead tuples behind. The
  #   heap keeps growing, so page counts — and with them sequential scan costs
  #   and buffer counts — creep upwards on every run.
  # * Planner statistics. The seed inserts its rows seconds before EXPLAIN
  #   runs and autovacuum will not have visited the tables yet, so Postgres
  #   plans from default heuristics (estimating 300 rows against an actual 73)
  #   and whether it has real statistics by then is a race.
  #
  # TRUNCATE ... RESTART IDENTITY fixes the first two; VACUUM ANALYZE reclaims
  # the space and gathers the statistics. Neither can run inside a transaction
  # block, which is why the generator is tagged `no_db_clean`.
  class Database
    SEQUENCES = %w[version_order_sequence verification_number_sequence].freeze

    def self.reset(db: PactBroker::DB.connection)
      return false unless postgres?(db)

      tables = PactBroker::DB::TableDependencyCalculator.call(db).select { |t| db.table_exists?(t) }
      db.run("TRUNCATE TABLE #{tables.map { |t| db.literal(Sequel.identifier(t)) }.join(', ')} RESTART IDENTITY CASCADE")
      SEQUENCES.each { |sequence| db.run("ALTER SEQUENCE #{sequence} RESTART") }
      true
    end

    # VACUUM ANALYZE rather than a bare ANALYZE: the truncate above leaves the
    # tables empty but the vacuum is what guarantees the seeded rows are the
    # only ones the planner's page counts reflect.
    def self.refresh_statistics(db: PactBroker::DB.connection)
      return false unless postgres?(db)

      db.run("VACUUM ANALYZE")
      true
    end

    def self.postgres?(db)
      db.adapter_scheme.to_s =~ /postgres/ ? true : false
    end
    private_class_method :postgres?
  end
end
