require 'support/test_data_builder'
require 'webmock/rspec'
require 'rack/pact_broker/database_transaction'

describe "Execute a webhook" do
  before do
    td.create_pact_with_hierarchy("Foo", "1", "Bar")
    allow(PactBroker.configuration).to receive(:webhook_scheme_whitelist).and_return(%w[http])
  end

  let(:params) do
    {
      request: {
        method: 'POST',
        url: 'http://example.org',
        headers: {'Content-Type' => 'application/json'},
        body: '${pactbroker.pactUrl}'
      }
    }
  end
  let(:rack_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json" } }

  let(:path) { "/webhooks/execute" }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}

  subject { post(path, params.to_json, rack_headers) }

  context "when the execution is successful" do
    let!(:request) do
      stub_request(:post, /http/).with(body: expected_webhook_url).to_return(:status => 200, body: response_body)
    end

    let(:expected_webhook_url) { %r{http://example.org/pacts/provider/Bar/consumer/Foo.*} }
    let(:response_body) { "webhook-response-body" }

    it "performs the HTTP request" do
      subject
      expect(request).to have_been_made
    end

    it "returns a 200 response" do
      expect(subject.status).to be 200
    end
  end

  context "when there is a validation error" do
    let(:params) { {} }

    it "returns a 400" do
      expect(subject.status).to be 400
    end
  end
end
