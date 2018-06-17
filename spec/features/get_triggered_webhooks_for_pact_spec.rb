RSpec.describe "Get triggered webhooks for pact" do
  before do
    td.create_pact_with_hierarchy
      .create_webhook
      .create_triggered_webhook
      .create_webhook_execution
  end

  let(:td) { TestDataBuilder.new }
  let(:path) { PactBroker::Api::PactBrokerUrls.pact_triggered_webhooks_url(td.pact) }
  let(:json_response_body) { JSON.parse(subject.body) }

  subject { get(path); last_response }

  it { is_expected.to be_a_hal_json_success_response }

  it "contains a list of triggered webhooks" do
    expect(json_response_body['_embedded']['triggeredWebhooks'].size).to be 1
  end
end
