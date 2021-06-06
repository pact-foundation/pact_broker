require "support/test_data_builder"
require "pact_broker/api/pact_broker_urls"

describe "Delete a verification" do
  let!(:verification) do
    TestDataBuilder.new
      .create_pact_with_verification("Foo", "1", "Bar", "2")
      .create_provider_webhook(event_names: ["provider_verification_published"])
      .create_triggered_webhook
      .create_webhook_execution
      .and_return(:verification)
  end

  let(:path) { PactBroker::Api::PactBrokerUrls.verification_url(verification, "") }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}

  subject { delete(path) }

  it "deletes the verification" do
    expect { subject }.to change { PactBroker::Domain::Verification.count }.by(-1)
  end

  it "returns a 204 response" do
    subject
    expect(last_response.status).to eq 204
  end
end
