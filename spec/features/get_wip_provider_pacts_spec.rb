describe "Get pending provider pacts" do
  subject { get path; last_response }

  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:pact_links) { last_response_body[:_links][:'pb:pacts'] }

  context "when the provider exists" do
    before do
      TestDataBuilder.new
        .create_provider("Provider")
        .create_consumer("Consumer")
        .create_consumer_version("0.0.1")
        .create_pact
    end

    let(:path) { "/pacts/provider/Provider/pending" }

    it "returns a 200 HAL JSON response" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "returns a list of links to the pacts" do
      expect(pact_links.size).to eq 1
    end
  end
end
