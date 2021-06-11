describe "retrieving tagged pact versions" do

  let(:path) { "/pacts/provider/Provider/consumer/Consumer/tag/prod"}

  subject { get(path) }
  let(:json_response_body) { JSON.parse(subject.body) }

  before do
    TestDataBuilder.new
      .create_consumer("Consumer")
      .create_provider("Provider")
      .create_consumer_version("1.2.3")
      .create_consumer_version_tag("prod")
      .create_pact
      .create_consumer_version("4.5.6")
      .create_pact
  end

  it "returns a 200 HAL JSON response" do
    expect(subject).to be_a_hal_json_success_response
  end

  it "returns the list of tagged pact versions" do
    expect(json_response_body["_links"]["pb:pact-versions"]).to be_a Array
  end
end
