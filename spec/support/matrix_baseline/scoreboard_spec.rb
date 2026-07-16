require "support/matrix_baseline/scoreboard"
require "support/matrix_baseline/shapes"

module MatrixBaseline
  describe Scoreboard do
    let(:shape) { Shapes::Shape.new("single_selector_version", "1 selector", :matrix, [], {}) }
    let(:statements) { ["SELECT a FROM p", "SELECT b FROM v"] }
    let(:plans) { { "SELECT a FROM p" => "Seq Scan on p", "SELECT b FROM v" => "Seq Scan on v" } }

    describe ".section" do
      subject(:section) { Scoreboard.section(shape, statements, plans) }

      it "wraps the shape and each statement in nested collapsible blocks" do
        expect(section).to include("<details>")
        expect(section).to include("<summary>")
        expect(section).to include("1 selector")
        expect(section).to include("<code>single_selector_version</code>")
        expect(section).to include("2 queries")
      end

      it "includes each statement's SQL and plan" do
        expect(section).to include("SELECT a FROM p")
        expect(section).to include("Seq Scan on p")
        expect(section).to include("SELECT b FROM v")
        expect(section).to include("Seq Scan on v")
      end

      it "falls back when a plan is missing" do
        section_without_plan = Scoreboard.section(shape, ["SELECT x"], {})
        expect(section_without_plan).to include("(no plan captured)")
      end
    end

    describe ".document" do
      it "wraps sections with a title and the adapter name" do
        doc = Scoreboard.document("postgres", ["<details>one</details>", "<details>two</details>"])
        expect(doc).to include("# Matrix query baseline")
        expect(doc).to include("Adapter: postgres")
        expect(doc).to include("<details>one</details>")
        expect(doc).to include("<details>two</details>")
      end
    end
  end
end
