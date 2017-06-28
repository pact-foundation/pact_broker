require 'spec/support/test_data_builder'

describe "Get diff between versions" do

  let(:path) { "/pacts/provider/Provider/consumer/Consumer/version/3/diff/previous-distinct" }

  let(:last_response_body) { subject.body }

  subject { get path; last_response }

  let(:pact_content_version_1) do
    hash = load_json_fixture('consumer-provider.json')
    hash['interactions'].first['request']['method'] = 'post'
    hash.to_json
  end
  let(:pact_content_version_2) { load_fixture('consumer-provider.json') }
  let(:pact_content_version_3) { pact_content_version_2 }

  before do
    TestDataBuilder.new
      .create_consumer("Consumer")
      .create_provider("Provider")
      .create_consumer_version("1")
      .create_pact(json_content: pact_content_version_1)
      .create_consumer_version("2")
      .create_pact(json_content: pact_content_version_2)
      .create_consumer_version("3")
      .create_pact(json_content: pact_content_version_3)
  end

  context "when the versions exist" do

    it "returns a 200 text response" do
      expect(subject.headers['Content-Type']).to eq "text/plain;charset=utf-8"
    end

    it "returns the JSON representation of the diff" do
      expect(last_response_body).to include('"method": "post"')
      expect(last_response_body).to include('"method": "get"')
    end

  end

  context "when either version does not exist" do

    let(:path) { "/pacts/provider/Provider/consumer/Consumer/versions/1/diff/previous-distinct" }

    it "returns a 404 response" do
      expect(subject).to be_a_404_response
    end

  end
end
