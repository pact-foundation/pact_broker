require 'support/provider_state_builder'

describe "Creating a webhook" do

  before do
    ProviderStateBuilder.new.create_pact_with_hierarchy("Some Consumer", "1", "Some Provider")
  end

  let(:path) { "/webhooks/provider/Some%20Provider/consumer/Some%20Consumer" }
  let(:headers) { {'CONTENT_TYPE' => 'application/json'} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}
  let(:webhook_json) { webhook_hash.to_json }

  subject { post path, webhook_json, headers }

  context "with invalid attributes" do

    let(:webhook_hash) { {} }

    it "returns a 400" do
      subject
      expect(last_response.status).to be 400
    end

    it "returns a JSON content type" do
      subject
      expect(last_response.headers['Content-Type']).to eq 'application/json;charset=utf-8'
    end

    it "returns the validation errors" do
      subject
      expect(response_body[:errors]).to_not be_empty
    end

  end

  context "with valid attributes" do

    let(:webhook_hash) do
      {
        request: {
          method: 'POST',
          url: 'http://example.org',
          headers: {
            :"Content-Type" => "application/json"
          },
          body: {
            a: 'body'
          }
        }
      }
    end

    let(:webhook_json) { webhook_hash.to_json }

    it "returns a 201 response" do
      subject
      expect(last_response.status).to be 201
    end

    it "returns the Location header" do
      subject
      expect(last_response.headers['Location']).to match(%r{http://example.org/webhooks/.+})
    end

    it "returns a JSON Content Type" do
      subject
      expect(last_response.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
    end

    it "returns the newly created webhook" do
      subject
      expect(response_body).to include webhook_hash
    end
  end

end
