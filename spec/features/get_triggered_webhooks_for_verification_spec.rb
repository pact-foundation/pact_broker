RSpec.describe "Get triggered webhooks for verification" do
  before do
    td.create_pact_with_hierarchy
      .create_verification_webhook
      .create_verification
      .create_triggered_webhook
      .create_webhook_execution
  end

  let(:path) { PactBroker::Api::PactBrokerUrls.verification_triggered_webhooks_url(td.verification) }
  let(:json_response_body) { JSON.parse(subject.body) }

  subject { get(path); last_response }

  it { is_expected.to be_a_hal_json_success_response }

  it "contains a list of triggered webhooks" do
    expect(json_response_body["_embedded"]["triggeredWebhooks"].size).to be 1
  end
end
