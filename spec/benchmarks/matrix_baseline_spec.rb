require "fileutils"
require "pact_broker/matrix/repository"
require "pact_broker/matrix/service"
require "support/matrix_baseline/query_capture"
require "support/matrix_baseline/explain"
require "support/matrix_baseline/seed"
require "support/matrix_baseline/shapes"
require "support/matrix_baseline/scoreboard"

module MatrixBaseline
  ARTIFACT_DIR = "docs/matrix-optimisation".freeze

  describe "matrix query baseline", matrix_baseline: true do
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

    it "generates the baseline for a Postgres database" do
      adapter = PactBroker::DB.connection.adapter_scheme.to_s
      unless adapter =~ /postgres/
        skip "baselines are generated against Postgres only; point PACT_BROKER_TEST_DATABASE_URL at a Postgres database (see docs/matrix-optimisation/README.md)"
      end

      td = TestDataBuilder.new
      seed = Seed.call(td)

      shapes = Shapes.call(seed)
      any_real_plan = false

      sections = shapes.map do |shape|
        statements = QueryCapture.call { run_shape(shape) }
        plans = statements.uniq.each_with_object({}) do |sql, acc|
          acc[sql] = begin
            Explain.call(sql)
          rescue => e
            "(EXPLAIN failed: #{e.class}: #{e.message})"
          end
        end
        any_real_plan ||= plans.values.any? { |plan| !plan.start_with?("(EXPLAIN failed") }
        expect(statements).to_not be_empty
        Scoreboard.section(shape, statements, plans)
      end

      expect(any_real_plan).to be(true), "every EXPLAIN failed across all shapes — baseline would be degenerate"

      FileUtils.mkdir_p(ARTIFACT_DIR)
      path = File.join(ARTIFACT_DIR, "baseline-#{adapter}.md")
      File.write(path, Scoreboard.document(adapter, sections))

      contents = File.read(path)
      expect(contents).to include("<details>")
      shapes.each { |shape| expect(contents).to include(shape.id) }
    end
  end
end
