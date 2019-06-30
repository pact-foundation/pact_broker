require 'pact_broker/secrets/secret'

RSpec.describe "creating a secret", secret_key: true do
  let!(:secret) { td.create_secret.and_return(:secret) }
  let(:path) { "/secrets/#{secret.uuid}" }
  let(:request_body) { { name: "updated name", value: "updated value" }.to_json }
  let(:rack_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json"} }
  let(:response_body_hash) { JSON.parse(subject.body) }

  subject { put(path, request_body, rack_headers) }

  context "when the encryption key is configured" do
    it "updates the secret" do
      expect { subject }.to change { PactBroker::Secrets::Secret.first.value }
    end

    it "returns a 200 HAL JSON response" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "returns the newly created secret without the value" do
      expect(response_body_hash["name"]).to eq "updated name"
      expect(response_body_hash).to_not have_key("value")
    end
  end
end
