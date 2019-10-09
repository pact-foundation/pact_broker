describe "get metrics" do
  let(:path) { "/metrics"}
  let(:json_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path)  }

  before do
    TestDataBuilder.new
      .create_consumer("Consumer")
      .create_provider("Provider")
      .create_consumer_version("1.2.3")
      .create_consumer_version_tag("prod")
      .create_pact
      .create_verification(provider_version: "4.5.6")
      .create_webhook
      .create_triggered_webhook
      .create_webhook_execution
  end

  it "returns some metrics" do
    puts json_response_body
    require 'pry'; pry(binding);
    expect(json_response_body[:pacticipants]).to be_instance_of(Hash)
  end
end
