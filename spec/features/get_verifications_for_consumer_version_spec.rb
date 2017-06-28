require 'spec/support/test_data_builder'

describe "Get verifications for consumer version" do

  let(:path) { "/verification-results/consumer/Consumer/version/1.2.3/latest" }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get path; last_response }

  context "when the consumer exists" do

    before do
      TestDataBuilder.new
        .create_provider("Provider")
        .create_consumer("Consumer")
        .create_consumer_version("1.2.3")
        .create_pact
        .create_verification(number: 1)
        .create_verification(number: 2)
        .create_provider("Another provider")
        .create_pact
        .create_verification(number: 1)
    end

    it "returns a 200 HAL JSON response" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "returns a list of verifications" do
      expect(last_response_body[:_embedded][:verificationResults].size).to eq 2
    end
  end
end
