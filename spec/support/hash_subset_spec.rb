require "support/hash_subset"

describe HashSubset do
  describe ".match?" do
    it "matches equal scalars" do
      expect(HashSubset.match?(1, 1)).to be true
      expect(HashSubset.match?("a", "b")).to be false
    end

    it "allows extra keys in the actual hash by default" do
      expect(HashSubset.match?({ "a" => 1 }, { "a" => 1, "b" => 2 })).to be true
    end

    it "rejects extra keys when allow_unexpected_keys is false" do
      expect(HashSubset.match?({ "a" => 1 }, { "a" => 1, "b" => 2 }, allow_unexpected_keys: false)).to be false
    end

    it "rejects a missing key" do
      expect(HashSubset.match?({ "a" => 1 }, {})).to be false
    end

    it "recurses into nested hashes" do
      expect(HashSubset.match?({ "a" => { "b" => 1 } }, { "a" => { "b" => 1, "c" => 2 } })).to be true
      expect(HashSubset.match?({ "a" => { "b" => 1 } }, { "a" => { "b" => 2 } })).to be false
    end

    it "requires arrays to have the same length and matching elements" do
      expect(HashSubset.match?([{ "a" => 1 }], [{ "a" => 1, "b" => 2 }])).to be true
      expect(HashSubset.match?([1, 2], [1])).to be false
      expect(HashSubset.match?([1], [1, 2])).to be false
    end

    it "does not treat a string key and a symbol key as the same" do
      expect(HashSubset.match?({ a: 1 }, { "a" => 1 })).to be false
    end
  end

  describe ".diff" do
    it "returns a unified diff of the pretty-printed hashes" do
      diff = HashSubset.diff({ "a" => 1 }, { "a" => 2 })
      expect(diff).to include "-  \"a\": 1"
      expect(diff).to include "+  \"a\": 2"
    end
  end
end
