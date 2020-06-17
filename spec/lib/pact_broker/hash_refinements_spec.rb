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

    describe "camelcase_keys" do
      let(:hash_1) do
        {
          "foo_bar" => {
            :meep_moop => "blahBlah",
            "beepBoop" => ""
          }
        }
      end

      let(:expected) do
        {
          "fooBar" => {
            :meepMoop => "blahBlah",
            "beepBoop" => ""
          }
        }
      end

      it "camel cases the keys" do
        expect(hash_1.camelcase_keys).to eq expected
      end
    end

    describe "snakecase_keys" do
      let(:hash_1) do
        {
          "fooBar" => {
            :meepMoop => "blahBlah",
            "already_snake" => ""
          }
        }
      end

      let(:expected) do
        {
          "foo_bar" => {
            :meep_moop => "blahBlah",
            "already_snake" => ""
          }
        }
      end

      it "snake cases the keys" do
        expect(hash_1.snakecase_keys).to eq expected
      end
    end
  end
end
