require 'support/test_data_builder'

describe "Updating a webhook" do
  let(:webhook) do
    TestDataBuilder.new
      .create_pact_with_hierarchy("Some Consumer", "1", "Some Provider")
      .create_global_webhook
      .and_return(:webhook)
  end

  let(:headers) { {'CONTENT_TYPE' => 'application/json'} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}
  let(:webhook_json) { webhook_hash.to_json }
  let(:webhook_hash) do
    {
      description: "trigger build",
      consumer: {
        name: "Some Consumer"
      },
      enabled: false,
      events: [{
        name: 'contract_published'
      }],
      request: {
        method: 'POST',
        url: 'https://example.org',
        headers: {
          :"Content-Type" => "application/json"
        },
        body: {
          a: 'body'
        }
      }
    }
  end

  subject { put(path, webhook_json, headers) }

  let(:path) { "/webhooks/#{webhook.uuid}" }

  context "with valid attributes" do
    it "returns the newly created webhook" do
      subject
      expect(response_body).to include description: "trigger build"
    end
  end
end
