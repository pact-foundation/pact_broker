require 'support/test_data_builder'

describe "Delete a webhook" do

  let!(:webhook) do
    TestDataBuilder.new
      .create_consumer("Some Consumer")
      .create_consumer_version("Some Provider")
      .create_provider
      .create_pact
      .create_webhook
      .create_triggered_webhook
      .create_webhook_execution
      .and_return(:webhook)
  end

  let(:path) { "/webhooks/#{webhook.uuid}" }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}
  let(:webhook_json) { webhook_hash.to_json }

  subject { delete path }

  it "deletes the webhook" do
    expect { subject }.to change { PactBroker::Webhooks::Webhook.count }.by(-1)
  end

  it "returns a 204 response" do
    subject
    expect(last_response.status).to eq 204
  end
end
