require 'pact_broker/secrets/secret'

RSpec.describe "creating a secret" do
  let(:path) { "/secrets" }
  let(:request_body) { { name: "token", value: "foo" }.to_json }
  let(:rack_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json"} }
  let(:response_body_hash) { JSON.parse(subject.body) }
  subject { post path, request_body, rack_headers }


  context "when the encryption key is configured", secret_key: true do
    it "creates a secret" do
      expect { subject }.to change { PactBroker::Secrets::Secret.count }.by(1)
    end

    it "returns a 200 HAL JSON response" do
      expect(subject).to be_a_hal_json_created_response
    end

    it "returns the newly created secret without the value" do
      expect(response_body_hash["name"]).to eq "token"
      expect(response_body_hash).to_not have_key("value")
    end
  end

  context "when the encryption key is not configured" do
    it "returns a 409" do
      expect(subject.status).to eq 409
    end
  end
end
