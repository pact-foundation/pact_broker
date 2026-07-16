require "support/matrix_baseline/explain"

module MatrixBaseline
  describe Explain do
    describe ".call" do
      it "returns a non-empty plan for a trivial query on the current adapter" do
        plan = Explain.call("SELECT 1")
        expect(plan).to be_a(String)
        expect(plan.strip).to_not be_empty
      end
    end
  end
end
