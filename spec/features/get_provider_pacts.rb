require 'spec/support/provider_state_builder'

describe "Get provider pacts" do

  let(:path) { "/pacts/provider/Provider/latest" }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get path; last_response }

  context "when the provider exists" do

    before do
      ProviderStateBuilder.new
        .create_consumer("Consumer")
        .create_consumer_version("1.2.3")
        .create_provider("Provider")
        .create_pact
        .create_consumer("Consumer 2")
        .create_consumer_version("4.5.6")
        .create_pact
    end


    it "returns a 200 HAL JSON response" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "returns the JSON representation of the pact" do
      expect(last_response_body[:_embedded][:pacts].size).to eq 2
    end

  end

  context "when the provider does not exist" do

    it "returns a 404 response" do
      expect(subject).to be_a_404_response
    end

  end
end
