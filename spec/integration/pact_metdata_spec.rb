RSpec.describe "the consumer version relations in the pact version resource" do
  context "when requested with no metadata" do
    before do
      td.create_pact_with_hierarchy("Foo", "1", "Bar")
        .create_consumer_version("2")
        .republish_same_pact
    end

    let(:pact_version_url) { PactBroker::Api::PactBrokerUrls.pact_version_url(td.and_return(:pact)) }

    subject { get(pact_version_url) }


    it "includes the consumer version of the latest version that published the pact" do
      body = JSON.parse(subject.body)
      consumer_version_relation = body["_links"]["pb:consumer-version"]
      expect(consumer_version_relation).to include("name" => "2")

      consumer_versions_relations = body["_links"]["pb:consumer-versions"]
      expect(consumer_versions_relations).to be nil
    end
  end
  context "for a pact published webhook" do
    before do
      td.create_global_webhook(event_names: ["contract_published"], body: { "pact_url" => "${pactbroker.pactUrl}" })
        .create_consumer("Foo")
        .create_provider("Bar")
        .create_consumer_version("1")
        .create_pact(json_content: pact_content)
    end

    let(:database_connector) { ->(&block) { block.call } }
    let(:pact_content) { td.random_json_content("Foo", "Bar") }

    let!(:webhook_request) do
      stub_request(:post, /http/).to_return(:status => 200)
    end

    let(:publish_pact) { put("/pacts/provider/Bar/consumer/Foo/version/2", pact_content, { "CONTENT_TYPE" => "application/json", "pactbroker.database_connector" => database_connector }) }

    let(:pact_version_response) do
      publish_pact
      pact_url = PactBroker::Webhooks::Execution.last.logs.scan(/(http:\/\/example.org\/pacts.*?)"/).last.last
      get(pact_url)
    end

    it "includes the consumer version of the version that just published the pact" do
      body = JSON.parse(pact_version_response.body)

      consumer_version_relation = body["_links"]["pb:consumer-version"]
      expect(consumer_version_relation).to include("name" => "2")

      consumer_versions_relations = body["_links"]["pb:consumer-versions"]
      expect(consumer_versions_relations.size).to eq 1
      expect(consumer_versions_relations).to contain_hash("name" => "2")
    end
  end

  context "for pacts for verification" do
    before do
      json_content = td.random_json_content("Foo", "Bar")
      td.create_consumer("Foo")
        .create_provider("Bar")
        .create_consumer_version("1", branch: "main")
        .create_pact(json_content: json_content)
        .create_consumer_version("2", branch: "feat/x")
        .create_pact(json_content: json_content)
        .create_consumer_version("2", branch: "feat/y")
        .create_pact(json_content: json_content)
        .create_consumer_version("3", branch: "feat/z")
    end

    let(:pacts_for_verification_request_body) do
      {
        consumerVersionSelectors: [ { branch: "main" }, { branch: "feat/x" }, { branch: "feat/y" } ],
      }.to_json
    end

    let(:rack_headers) do
      {
        "HTTP_ACCEPT" => "application/hal+json"
      }
    end

    let(:pacts_for_verification) do
      response = post("/pacts/provider/Bar/for-verification", pacts_for_verification_request_body, rack_headers)
      JSON.parse(response.body)["_embedded"]["pacts"]
    end

    let(:pact_version_url) do
      pacts_for_verification[0]["_links"]["self"]["href"]
    end

    it "includes links for all the consumer versions for which it was selected" do
      body = JSON.parse(get(pact_version_url).body)
      consumer_version_relation = body["_links"]["pb:consumer-version"]
      expect(consumer_version_relation).to include("name" => "2")

      consumer_versions_relations = body["_links"]["pb:consumer-versions"]
      expect(consumer_versions_relations.size).to eq 2
      expect(consumer_versions_relations).to contain_hash("name" => "2")
      expect(consumer_versions_relations).to contain_hash("name" => "1")
    end
  end
end
