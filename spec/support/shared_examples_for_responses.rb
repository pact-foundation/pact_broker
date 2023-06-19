shared_examples_for "a JSON 404 response" do
  it "returns a 404 Not Found" do
    subject
    expect(last_response.status).to eq 404
  end
end

shared_examples_for "a 200 JSON response" do

end

shared_examples_for "a paginated response" do
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

  it "includes the pagination relations" do
    expect(response_body_hash[:_links]).to have_key(:next)
  end

  it "includes the page details" do
    expect(response_body_hash).to include(
      page: {
        number: instance_of(Integer),
        size: instance_of(Integer),
        totalElements: instance_of(Integer),
        totalPages: instance_of(Integer),
      }
    )
  end
end

require "rspec/expectations"

RSpec::Matchers.define :be_a_hal_json_success_response do
  match do | actual |
    expect(actual.status).to be 200
    expect(actual.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
  end

  failure_message do
    "Expected successful json response, got #{actual.status} #{actual.headers['Content-Type']} with body #{actual.body}"
  end
end

RSpec::Matchers.define :be_a_hal_json_created_response do
  match do | actual |
    expect(actual.status).to be 201
    expect(actual.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
  end

  failure_message do
    "Expected creation successful json response, got #{actual.status} #{actual.headers['Content-Type']} with body #{actual.body}"
  end
end

RSpec::Matchers.define :be_a_json_response do
  match do | actual |
    expect(actual.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
  end
end

RSpec::Matchers.define :be_a_json_error_response do | message |
  match do | actual |
    expect(actual.status).to be 400
    expect(actual.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
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
    keys.each_with_object({}) do |k, hash|
      if (actual.respond_to?(:has_key?) && actual.has_key?(k))
        hash[k] = actual[k]
      elsif actual.respond_to?(k)
        hash[k] = actual.send(k)
      end
    end
  end
end

RSpec::Matchers.define :be_a_pact_never_verified_for_consumer do | expected_consumer_name |
  match do | actual_reason |
    expect(actual_reason).to be_a(PactBroker::Matrix::PactNotEverVerifiedByProvider)
    expect(actual_reason.consumer_selector.pacticipant_name).to eq expected_consumer_name
  end
end
