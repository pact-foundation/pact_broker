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
    expect(actual.headers['Content-Type']).to eq 'application/hal+json'
  end
end

RSpec::Matchers.define :be_a_404_response do
  match do | actual |
    expect(actual.status).to be 404
  end
end