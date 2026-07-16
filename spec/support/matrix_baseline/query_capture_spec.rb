require "support/matrix_baseline/query_capture"

module MatrixBaseline
  describe QueryCapture do
    let(:db) { PactBroker::DB.connection }

    it "captures the SQL of queries executed in the block, prefix stripped" do
      statements = QueryCapture.call do
        db["SELECT 1 AS one"].all
        db["SELECT 2 AS two"].all
      end

      expect(statements).to include(a_string_matching(/SELECT 1 AS one/i))
      expect(statements).to include(a_string_matching(/SELECT 2 AS two/i))
      expect(statements).to all( satisfy { |s| !s.start_with?("(") } ) # timing prefix removed
    end

    it "excludes transaction-control noise" do
      statements = QueryCapture.call do
        db.transaction { db["SELECT 1"].all }
      end
      expect(statements).to_not include(a_string_matching(/\A\s*(BEGIN|COMMIT|SAVEPOINT)/i))
    end

    it "removes its logger after the block, even on error" do
      before_count = db.loggers.size
      expect { QueryCapture.call { raise "boom" } }.to raise_error("boom")
      expect(db.loggers.size).to eq(before_count)
    end
  end
end
