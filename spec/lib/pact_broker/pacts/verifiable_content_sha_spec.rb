describe "" do
  let(:hash_1) do
    {
      a: '1',
      b: '2',
      c: {
        d: '3',
        e: '4'
      }
    }
  end

  let(:hash_2) do
    {
      c: {
        e: '4',
        d: '3'
      },
      b: '2',
      a: '1'
    }
  end

  def order_verifiable_content array
    array_with_ordered_hashes = order_hashes(array)
    array_with_ordered_hashes.sort{|a, b| a.to_json <=> b.to_json }
  end


  def order_hashes thing
    case thing
      when Hash then order_hash(thing)
      when Array then order_child_array(thing)
    else thing
    end
  end

  def order_child_array array
    array.collect{|thing| order_hashes(thing) }
  end

  def order_hash hash
    hash.keys.sort.each_with_object({}) do | key, new_hash |
      new_hash[key] = order_hashes(hash[key])
    end
  end

  it "" do
    expect(order_hashes(hash_1).to_json).to eq(order_hashes(hash_2).to_json)
  end

  context "with arrays containing hashes" do
    it "orders them by the hash of their contents" do
      expect(order_hashes([hash_2, hash_1]).to_json).to eq(order_hashes([hash_1, hash_2]).to_json)
    end
  end

  context "order array" do
    let(:array_1) do
      [1, hash_1, 3]
    end

    let(:array_2) do
      [hash_2, 3, 1]
    end

    it "orders them the same every time" do
      expect(order_verifiable_content(array_1).to_json).to eq(order_verifiable_content(array_2).to_json)
    end
  end
end