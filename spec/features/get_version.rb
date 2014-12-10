require 'spec/support/provider_state_builder'

describe "Get version" do

  context "when the version exists" do

    before do
      ProviderStateBuilder.new
        .create_consumer("Consumer")
        .create_version("1.2.3")
        .create_version("1.2.4")
    end

    let(:path) { "/pacticipants/Consumer/versions/1.2.3" }
    let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

    subject { get path; last_response }

    it "returns a 200 HAL JSON response" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "returns the JSON representation of the version" do
      expect(last_response_body).to include number: '1.2.3'
    end

  end

  context "when the version does not exist" do

    before do
      ProviderStateBuilder.new
        .create_consumer("Consumer")
        .create_version("1.2.4")
    end

    let(:path) { "/pacticipants/Consumer/versions/1.2.3" }

    subject { get path; last_response }

    it "returns a 404 response" do
      expect(subject).to be_a_404_response
    end

  end
end
