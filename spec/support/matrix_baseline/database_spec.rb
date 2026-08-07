require "support/matrix_baseline/database"

module MatrixBaseline
  describe Database do
    let(:postgres) do
      instance_double("Sequel::Database", adapter_scheme: :postgres).tap do |db|
        allow(db).to receive(:run)
        allow(db).to receive(:table_exists?).and_return(true)
        allow(db).to receive(:literal) { |identifier| %("#{identifier.value}") }
      end
    end

    let(:sqlite) do
      instance_double("Sequel::Database", adapter_scheme: :sqlite).tap do |db|
        allow(db).to receive(:run)
      end
    end

    describe ".reset" do
      before do
        allow(PactBroker::DB::TableDependencyCalculator).to receive(:call).and_return([:pacticipants, :versions])
      end

      it "truncates every table and rewinds the identity sequences" do
        expect(Database.reset(db: postgres)).to be(true)
        expect(postgres).to have_received(:run).with('TRUNCATE TABLE "pacticipants", "versions" RESTART IDENTITY CASCADE')
      end

      it "rewinds the sequences the schema manages by hand" do
        Database.reset(db: postgres)

        expect(postgres).to have_received(:run).with("ALTER SEQUENCE version_order_sequence RESTART")
        expect(postgres).to have_received(:run).with("ALTER SEQUENCE verification_number_sequence RESTART")
      end

      it "is a no-op on adapters the baseline is not generated against" do
        expect(Database.reset(db: sqlite)).to be(false)
        expect(sqlite).to_not have_received(:run)
      end
    end

    describe ".refresh_statistics" do
      it "reclaims dead tuples and gathers planner statistics" do
        expect(Database.refresh_statistics(db: postgres)).to be(true)
        expect(postgres).to have_received(:run).with("VACUUM ANALYZE")
      end

      it "is a no-op on adapters with no planner statistics to refresh" do
        expect(Database.refresh_statistics(db: sqlite)).to be(false)
        expect(sqlite).to_not have_received(:run)
      end
    end
  end
end
