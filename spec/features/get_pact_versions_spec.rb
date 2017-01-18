require 'spec/support/provider_state_builder'

describe "Get pact versions" do

  let(:path) { "/pacts/provider/Provider/consumer/Consumer/versions" }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get path; last_response }

  context "when the pacts exist" do

    before do
      ProviderStateBuilder.new
        .create_provider("Provider")
        .create_consumer("Consumer")
        .create_consumer_version("1.0.0")
        .create_pact
        .create_consumer_version("1.0.1")
        .create_pact
    end

    it "returns a 200 HAL JSON response" do
      expect(subject.status).to be 200
    end

    it "returns a list of links to the pacts" do
      expect(last_response_body[:_links][:"pact-versions"].size).to eq 2
    end

  end

  context "when the pacts do not exist" do

    it "returns a 404 response" do
      expect(subject).to be_a_404_response
    end

  end
end
