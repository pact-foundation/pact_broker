require "support/matrix_baseline/explain"

module MatrixBaseline
  describe Explain do
    describe ".call" do
      it "returns a non-empty plan for a trivial query on the current adapter" do
        plan = Explain.call("SELECT 1")
        expect(plan).to be_a(String)
        expect(plan.strip).to_not be_empty
      end

      it "raises for an adapter that has no EXPLAIN dialect" do
        db = instance_double("Sequel::Database", adapter_scheme: :oracle)
        expect { Explain.call("SELECT 1", db: db) }.to raise_error(ArgumentError, /unsupported adapter/)
      end

      context "on Postgres" do
        let(:plan_rows) do
          [
            { "QUERY PLAN" => "Seq Scan on pacticipants  (cost=0.00..13.00 rows=300 width=36) (actual rows=73 loops=1)" },
            { "QUERY PLAN" => "  Buffers: shared hit=4" },
            { "QUERY PLAN" => "Planning Time: 0.153 ms" },
            { "QUERY PLAN" => "Execution Time: 1.402 ms" },
          ]
        end

        let(:db) do
          instance_double("Sequel::Database", adapter_scheme: :postgres).tap do |db|
            allow(db).to receive(:[]).and_return(double(all: plan_rows))
          end
        end

        it "asks Postgres for buffers and row counts but not per-node timings" do
          Explain.call("SELECT 1", db: db)
          expect(db).to have_received(:[]).with(/EXPLAIN \(ANALYZE, BUFFERS, TIMING OFF, FORMAT TEXT\) SELECT 1/)
        end

        it "strips the wall-clock summary lines so unchanged code yields an identical plan" do
          plan = Explain.call("SELECT 1", db: db)
          expect(plan).to_not include("Planning Time")
          expect(plan).to_not include("Execution Time")
        end

        it "keeps the buffer counts and row estimates that describe query cost" do
          plan = Explain.call("SELECT 1", db: db)
          expect(plan).to include("Buffers: shared hit=4")
          expect(plan).to include("rows=300")
          expect(plan).to include("actual rows=73")
        end
      end
    end
  end
end
