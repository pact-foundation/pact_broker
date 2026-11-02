require "pact_broker/hash_refinements"

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

    describe "symbolize_keys" do
      let(:hash_1) do
        {
          "foo" => {
            "bar" => [{ "baz" => 1 }, "string", 2],
            :already_symbol => nil
          },
          "meep" => "moop"
        }
      end

      let(:expected) do
        {
          foo: {
            bar: [{ baz: 1 }, "string", 2],
            already_symbol: nil
          },
          meep: "moop"
        }
      end

      it "symbolizes the keys of nested hashes, including hashes inside arrays" do
        expect(hash_1.symbolize_keys).to eq expected
      end

      it "preserves the order of the keys" do
        expect(hash_1.symbolize_keys.keys).to eq [:foo, :meep]
      end

      it "does not modify the original hash" do
        original = Marshal.load(Marshal.dump(hash_1))
        hash_1.symbolize_keys
        expect(hash_1).to eq original
      end

      context "when a string key and a symbol key have the same name" do
        let(:hash_1) { { "foo" => 1, :foo => 2 } }

        it "uses the last value" do
          expect(hash_1.symbolize_keys).to eq(foo: 2)
        end
      end
    end
  end
end
