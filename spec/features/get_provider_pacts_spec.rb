require 'spec/support/test_data_builder'

describe "Get provider pacts" do

  let(:path) { "/pacts/provider/Provider/latest" }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get path; last_response }

  context "when the provider exists" do

    before do
      TestDataBuilder.new
        .create_provider("Provider")
        .create_consumer("Consumer")
        .create_consumer_version("1.0.0")
        .create_consumer_version_tag("prod")
        .create_pact
        .create_consumer_version("1.2.3")
        .create_pact
        .create_consumer("Consumer 2")
        .create_consumer_version("4.5.6")
        .create_pact
    end

    context "with no tag specified" do

      it "returns a 200 HAL JSON response" do
        expect(subject).to be_a_hal_json_success_response
      end

      it "returns a list of links to the pacts" do
        expect(last_response_body[:_links][:pacts].size).to eq 2
      end
    end

    context "with a tag specified" do

      let(:path) { "/pacts/provider/Provider/latest/prod" }

      it "returns a 200 HAL JSON response" do
        expect(subject).to be_a_hal_json_success_response
      end

      it "returns a list of links to the pacts" do
        expect(last_response_body[:_links][:pacts].size).to eq 1
      end
    end

    context "with a tag with no pacts" do

      let(:path) { "/pacts/provider/Provider/latest/foo" }

      it "returns a 200 HAL JSON response" do
        expect(subject).to be_a_hal_json_success_response
      end

      it "returns a list of links to the pacts" do
        expect(last_response_body[:_links][:pacts].size).to eq 0
      end
    end

  end

  context "when the provider does not exist" do

    it "returns a 404 response" do
      expect(subject).to be_a_404_response
    end

  end
end
