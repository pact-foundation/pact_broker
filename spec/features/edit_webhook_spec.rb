require "support/test_data_builder"

describe "Creating a webhook" do
  before do
    td.create_pact_with_hierarchy("Some Consumer", "1", "Some Provider")
      .create_webhook
  end

  let(:path) { "/webhooks/#{td.webhook.uuid}" }
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}
  let(:webhook_json) do
    h = load_json_fixture("webhook_valid.json")
    h["request"]["url"] = "https://bar.com"
    h.to_json
  end

  let(:reloaded_webhook) { PactBroker::Webhooks::Repository.new.find_by_uuid(td.webhook.uuid) }

  subject { put path, webhook_json, headers; last_response }

  context "with invalid attributes" do
    let(:webhook_json) { "{}" }

    it "returns a 400" do
      subject
      expect(last_response.status).to be 400
    end

    it "returns the validation errors" do
      subject
      expect(response_body[:errors]).to_not be_empty
    end

    it "does not update the webhook" do
      expect(reloaded_webhook.request.method).to eq "POST"
    end
  end

  context "with valid attributes" do
    let(:webhook_hash) { JSON.parse(webhook_json, symbolize_names: true) }

    it "returns a 200 response" do
      subject
      expect(last_response.status).to be 200
    end

    it "returns a JSON Content Type" do
      subject
      expect(last_response.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
    end

    it "updates the webhook" do
      subject
      expect(reloaded_webhook.request.url).to eq "https://bar.com"
    end
  end
end
