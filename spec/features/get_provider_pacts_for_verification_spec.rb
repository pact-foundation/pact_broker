describe "Get provider pacts for verification" do
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:pacts) { last_response_body[:_embedded][:'pacts'] }
  subject { get path; last_response }

  context "when the provider exists" do
    before do
      TestDataBuilder.new
        .create_provider("Provider")
        .create_consumer("Consumer")
        .create_consumer_version("0.0.1")
        .create_pact
        .create_consumer("Consumer 2")
        .create_consumer_version("4.5.6")
        .create_consumer_version_tag("prod")
        .create_pact
    end

    context "with no tag specified" do
      let(:path) { "/pacts/provider/Provider/for-verification" }

      it "returns a 200 HAL JSON response" do
        expect(subject).to be_a_hal_json_success_response
      end

      it "returns a list of links to the pacts" do
        expect(pacts.size).to eq 2
      end
    end
  end

  context "when the provider does not exist" do
    let(:path) { "/pacts/provider/Provider" }

    it "returns a 404 response" do
      expect(subject).to be_a_404_response
    end
  end
end
