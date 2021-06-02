require "spec/support/test_data_builder"

describe "Get version" do

  let(:path) { "/pacticipants/Consumer/versions/1.2.3" }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get path; last_response }

  context "when the version exists" do

    before do
      TestDataBuilder.new
        .create_consumer("Another Consumer")
        .create_consumer("Consumer")
        .create_consumer_version("1.2.3")
        .create_consumer_version_tag("prod")
        .create_consumer_version("1.2.4")
    end

    it "returns a 200 HAL JSON response" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "returns the JSON representation of the version" do
      expect(last_response_body).to include number: "1.2.3"
    end

  end

  context "when the version does not exist" do

    before do
      TestDataBuilder.new
        .create_consumer("Consumer")
        .create_version("1.2.4")
    end

    it "returns a 404 response" do
      expect(subject).to be_a_404_response
    end

  end
end
