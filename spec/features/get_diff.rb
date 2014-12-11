require 'spec/support/provider_state_builder'

describe "Get diff between versions" do

  let(:path) { "/pacts/provider/Provider/consumer/Consumer/version/3/diff/previous-distinct" }

  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get path; last_response }

  let(:pact_content_version_1) do
    hash = load_json_fixture('consumer-provider.json')
    hash['interactions'].first['request']['method'] = 'post'
    hash.to_json
  end
  let(:pact_content_version_2) { load_fixture('consumer-provider.json') }
  let(:pact_content_version_3) { pact_content_version_2 }

  before do
    ProviderStateBuilder.new
      .create_consumer("Consumer")
      .create_provider("Provider")
      .create_consumer_version("1")
      .create_pact(pact_content_version_1)
      .create_consumer_version("2")
      .create_pact(pact_content_version_2)
      .create_consumer_version("3")
      .create_pact(pact_content_version_3)
  end

  context "when the versions exist" do

    it "returns a 200 HAL JSON response" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "returns the JSON representation of the diff" do
      expect(last_response_body).to include({})
    end

  end

  context "when either version does not exist" do

    let(:path) { "/pacts/provider/Provider/consumer/Consumer/versions/1/diff/previous-distinct" }

    xit "returns a 404 response" do
      expect(subject).to be_a_404_response
    end

  end
end
