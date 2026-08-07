require "fileutils"
require "pact_broker/matrix/repository"
require "pact_broker/matrix/service"
require "support/matrix_baseline/query_capture"
require "support/matrix_baseline/explain"
require "support/matrix_baseline/seed"
require "support/matrix_baseline/database"
require "support/matrix_baseline/shapes"
require "support/matrix_baseline/scoreboard"

module MatrixBaseline
  ARTIFACT_DIR = "docs/matrix-optimisation".freeze

  # no_db_clean: the generator manages its own database state. It needs
  # TRUNCATE ... RESTART IDENTITY and VACUUM, neither of which can run inside
  # the transaction DatabaseCleaner would otherwise wrap around the example.
  describe "matrix query baseline", matrix_baseline: true, no_db_clean: true do
    def run_shape(shape)
      case shape.kind
      when :matrix
        PactBroker::Matrix::Repository.new.find(shape.selectors, shape.options)
      when :can_i_deploy
        PactBroker::Matrix::Service.can_i_deploy(shape.selectors, shape.options)
      else
        raise ArgumentError, "unknown shape kind: #{shape.kind}"
      end
    end

    # A failed EXPLAIN inside a transaction aborts it, and every later
    # statement — the next shape's query included — then fails with an
    # unrelated "current transaction is aborted", blaming the wrong shape. Its
    # own transaction keeps the failure local, so the recorded message names
    # the statement that actually caused it.
    def explain_in_transaction(sql, shape, failures)
      PactBroker::DB.connection.transaction do
        Explain.call(sql)
      end
    rescue => e
      failures << "#{shape.id}: #{e.class}: #{e.message.lines.first.to_s.strip}"
      "(EXPLAIN failed: #{e.class}: #{e.message})"
    end

    it "generates the baseline for a Postgres database" do
      adapter = PactBroker::DB.connection.adapter_scheme.to_s
      unless adapter =~ /postgres/
        skip "baselines are generated against Postgres only; point PACT_BROKER_TEST_DATABASE_URL at a Postgres database (see docs/matrix-optimisation/README.md)"
      end

      Database.reset
      seed = Seed.call(TestDataBuilder.new)
      Database.refresh_statistics

      shapes = Shapes.call(seed)
      failures = []

      sections = shapes.map do |shape|
        statements = QueryCapture.call { run_shape(shape) }
        plans = statements.uniq.each_with_object({}) do |sql, acc|
          acc[sql] = explain_in_transaction(sql, shape, failures)
        end
        expect(statements).to_not be_empty
        Scoreboard.section(shape, statements, plans)
      end

      expect(failures).to be_empty, "EXPLAIN failed for #{failures.size} statement(s); the baseline would record no plan for them:\n#{failures.join("\n")}"

      FileUtils.mkdir_p(ARTIFACT_DIR)
      path = File.join(ARTIFACT_DIR, "baseline-#{adapter}.md")
      File.write(path, Scoreboard.document(adapter, sections))

      contents = File.read(path)
      expect(contents).to include("<details>")
      shapes.each { |shape| expect(contents).to include(shape.id) }
    end
  end
end
