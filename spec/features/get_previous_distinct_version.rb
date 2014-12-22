require 'spec/support/provider_state_builder'

describe "Get previous distinct version of pact" do

  let(:path) { "/pacts/provider/Provider/consumer/Consumer/version/3/previous-distinct" }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get path; last_response }

  let(:pact_content_version_1) { load_fixture('consumer-provider.json') }
  let(:pact_content_version_2) do
    hash = load_json_fixture('consumer-provider.json')
    hash['interactions'].first['request']['method'] = 'post'
    hash.to_json
  end
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

  context "when the pact version exists" do

    it "returns a 200 HAL JSON response" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "returns the JSON representation of the version" do
      expect(last_response_body[:_links][:self][:href]).to end_with '/1'
    end

  end

  context "when the version does not exist" do

    let(:path) { "/pacts/provider/Provider/consumer/Consumer/version/1/previous-distinct" }

    it "returns a 404 response" do
      expect(subject).to be_a_404_response
    end

  end
end
