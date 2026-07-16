require "pact_broker/db"

module MatrixBaseline
  # Captures the SQL of every statement Sequel executes within the block,
  # including eager-load follow-up queries (which fire after the main query
  # materialises). Returns SQL strings with Sequel's "(0.000123s) " timing
  # prefix stripped and transaction-control statements removed.
  class QueryCapture
    TIMING_PREFIX = /\A\([0-9.e+-]+s\)\s*/.freeze
    TX_NOISE = /\A(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE|SET |PRAGMA)/i.freeze

    def self.call
      logger = new
      db = PactBroker::DB.connection
      db.loggers << logger
      begin
        yield
      ensure
        db.loggers.delete(logger)
      end
      logger.statements
    end

    def initialize
      @statements = []
    end

    attr_reader :statements

    # Sequel routes executed-query logs through these severities depending on
    # sql_log_level (the test suite's default is :trace, see
    # spec/support/test_database/connection.rb); capture them all but keep
    # only messages that carry the timing prefix (i.e. real executed
    # statements).
    def info(message);  record(message); end
    def debug(message); record(message); end
    def warn(message);  record(message); end
    def error(message); record(message); end
    def trace(message); record(message); end

    private

    def record(message)
      return unless message.is_a?(String) && message =~ TIMING_PREFIX
      sql = message.sub(TIMING_PREFIX, "")
      return if sql =~ TX_NOISE
      @statements << sql
    end
  end
end
