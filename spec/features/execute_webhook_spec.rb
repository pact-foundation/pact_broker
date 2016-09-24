require 'support/provider_state_builder'
require 'webmock/rspec'

describe "Executing a webhook" do

  before do
    ProviderStateBuilder.new
      .create_consumer("Consumer")
      .create_provider("Provider")
      .create_consumer_version("1")
      .create_pact
      .create_webhook(method: "post", url: "http://example.org/hook", body: "${PACT_VERSION_URL}")
  end

  let(:webhook_uuid) { PactBroker::Repositories::Webhook.first.uuid }
  let(:path) { "/webhooks/#{webhook_uuid}/execute" }

  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}

  subject { post path }

  let!(:http_request) do
    stub_request(:post, "http://example.org/hook").
      with(body: "http://example.org/pacts/provider/Provider/consumer/Consumer/version/1").
      to_return(:status => 200)
  end

  it "makes a HTTP request to the configured URL" do
    subject
    expect(http_request).to have_been_made
  end

end
