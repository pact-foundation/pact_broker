shared_examples_for "a JSON 404 response" do
  it "returns a 404 Not Found" do
    subject
    expect(last_response.status).to eq 404
  end
end

shared_examples_for "a 200 JSON response" do

end

require 'rspec/expectations'

RSpec::Matchers.define :be_a_hal_json_success_response do
  match do | actual |
    expect(actual.status).to be 200
    expect(actual.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
  end

  failure_message do
    "Expected successful json response, got #{actual.status} #{actual.headers['Content-Type']} with body #{actual.body}"
  end
end

RSpec::Matchers.define :be_a_json_response do
  match do | actual |
    expect(actual.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
  end
end

RSpec::Matchers.define :be_a_json_error_response do | message |
  match do | actual |
    expect(actual.status).to be 400
    expect(actual.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
    expect(actual.body).to include message
  end
end

RSpec::Matchers.define :be_a_404_response do
  match do | actual |
    expect(actual.status).to be 404
  end
end

RSpec::Matchers.define :include_hashes_matching do |expected_array_of_hashes|
  match do |array_of_hashes|
    expected_array_of_hashes.each do | expected |
      expect(array_of_hashes).to include_hash_matching(expected)
    end

    expect(array_of_hashes.size).to eq expected_array_of_hashes.size
  end

  def slice actual, keys
    keys.each_with_object({}) { |k, hash| hash[k] = actual[k] if actual.has_key?(k) }
  end
end

RSpec::Matchers.define :include_hash_matching do |expected|
  match do |array_of_hashes|
    @array_of_hashes = array_of_hashes
    array_of_hashes.any? { |actual| slice(actual, expected.keys) == expected }
  end

  failure_message do
    "expected #{@array_of_hashes.inspect} to include #{expected.inspect}"
  end

  def slice actual, keys
    keys.each_with_object({}) { |k, hash| hash[k] = actual[k] if (actual.respond_to?(:has_key?) && actual.has_key?(k)) || actual.respond_to?(k)  }
  end
end
