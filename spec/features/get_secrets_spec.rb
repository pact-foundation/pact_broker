require 'pact_broker/secrets/secret'

RSpec.describe "get secrets", secret_key: true do
  before do
    td.create_secret
  end

  let(:path) { "/secrets" }
  let(:rack_headers) { { "HTTP_ACCEPT" => "application/hal+json"} }
  let(:response_body_hash) { JSON.parse(subject.body) }

  subject { get path, nil, rack_headers }

  it "returns a 200 HAL JSON response" do
    expect(subject).to be_a_hal_json_success_response
  end

  it "returns a list of secrets" do
    expect(response_body_hash["_embedded"]["secrets"]).to be_instance_of(Array)
    expect(response_body_hash["_embedded"]["secrets"].size).to eq 1
  end
end
