require "spec/support/test_data_builder"

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

  context "when the consumer version has pacts with many providers" do
    def add_verified_pacts(provider_names)
      provider_names.each do |provider_name|
        td.create_provider(provider_name)
          .create_pact
          .create_verification(provider_version: "1")
      end
    end

    before do
      td.create_consumer("Consumer")
        .create_consumer_version("1.2.3", tag_names: ["main"])
    end

    it "runs the same number of queries regardless of the number of verifications" do
      add_verified_pacts(["Provider 0"])
      queries_for_one = count_select_queries { get(path) }

      add_verified_pacts((1...20).map { |i| "Provider #{i}" })
      queries_for_twenty = count_select_queries { get(path) }

      expect(last_response.status).to eq 200
      expect(JSON.parse(last_response.body)["_embedded"]["verificationResults"].size).to eq 20
      expect(queries_for_twenty).to eq queries_for_one
    end
  end
end
