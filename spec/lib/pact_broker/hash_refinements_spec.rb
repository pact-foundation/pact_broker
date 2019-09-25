require 'pact_broker/hash_refinements'

module PactBroker
  describe HashRefinements do
    using HashRefinements

    let(:a) { { a: 1, b: { c: 3 }, d: 5, e: nil } }
    let(:b) { { a: 2, b: { c: 4 } } }
    let(:expected) { { a: 2, b: { c: 4 }, d: 5, e: nil } }

    it "merges" do
      expect(a.deep_merge(b)).to eq expected
    end
  end
end
