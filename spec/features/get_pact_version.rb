RSpec.describe "retrieving a pact" do
  subject { get(path)  }

  context "when differing case is used in the consumer and provider names" do
    let(:pact) { td.create_pact_with_hierarchy("Foo", "1", "Bar").and_return(:pact) }
    let!(:path) { "/pacts/provider/Bar/consumer/Foo/pact-version/#{pact.pact_version_sha}" }

    it "returns a 200 Success" do
      expect(subject.status).to be 200
    end
  end

  context "when there are multiple consumer versions for the same sha" do
    before do
      td.create_pact_with_hierarchy("Foo", "1", "Bar")
        .create_consumer_version("2")
        .republish_same_pact
    end

    let(:pact) { PactBroker::Pacts::PactPublication.order(:id).first.to_domain }
    let(:path) { PactBroker::Api::PactBrokerUrls.pact_version_url(pact) }

    it "returns the latest" do
      expect(JSON.parse(subject.body)['_links']['pb:consumer-version']['name']).to eq "2"
    end

    context "when there is metadata specifying the consumer version number" do
      let(:pact) { PactBroker::Pacts::PactPublication.order(:id).first.to_domain }
      let(:path) { PactBroker::Api::PactBrokerUrls.pact_version_url_with_webhook_metadata(pact) }

      it "returns the pact with the matching consumer version number" do
        expect(JSON.parse(subject.body)['_links']['pb:consumer-version']['name']).to eq "1"
      end
    end
  end
end
