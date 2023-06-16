require "pact_broker/domain/verification"
require "timecop"

describe "Publishing a pact verification" do
  let(:path) { "/pacts/provider/Provider/consumer/Consumer/pact-version/#{pact.pact_version_sha}/verification-results" }
  let(:verification_content) { load_fixture("verification.json") }
  let(:parsed_response_body) { JSON.parse(subject.body) }
  let(:pact) { td.pact }
  let(:rack_env) do
    {
      "CONTENT_TYPE" => "application/json",
      "HTTP_ACCEPT" => "application/hal+json",
      "pactbroker.database_connector" => lambda { |&block| block.call }
    }
  end

  subject { post(path, verification_content, rack_env)  }

  before do
    Timecop.freeze(Date.today - 2) do
      td.create_provider("Provider")
        .create_consumer("Consumer")
        .create_consumer_version("1.0.0")
        .create_pact
        .create_consumer_version("1.2.3")
        .create_pact
        .revise_pact
    end
  end

  it "updates the contract_data_updated_at on the integration" do
    expect { subject }.to change { PactBroker::Integrations::Integration.last.contract_data_updated_at }
  end

  context "with a webhook configured", job: true do
    before do
      td.create_webhook(
        method: "POST",
        url: "http://example.org",
        events: [{ name: PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED }]
      )
    end
    let!(:request) do
      stub_request(:post, "http://example.org").to_return(:status => 200)
    end

    it "executes the webhook" do
      subject
      expect(request).to have_been_made
    end
  end
end
