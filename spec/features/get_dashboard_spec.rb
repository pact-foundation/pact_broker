describe "Get dashboard" do

  let(:path) { "/dashboard" }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  before do
    TestDataBuilder.new
      .create_consumer("Foo")
      .create_provider("Bar")
      .create_consumer_version("1.2.3")
      .create_pact
      .create_verification
      .create_webhook
      .create_triggered_webhook
      .create_webhook_execution
  end

  subject { get path; last_response }

  it "returns a 200 HAL JSON response" do
    expect(subject).to be_a_hal_json_success_response
  end

  it "returns a list of items" do
    items = JSON.parse(subject.body)['items']
    expect(items).to be_instance_of(Array)
  end
end
