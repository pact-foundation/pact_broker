require "webmock/rspec"
require "pact_broker/api/pact_broker_urls"

RSpec.describe "passing the pact selection criteria through the verification results to the triggered webhooks" do
  before do
    allow(PactBroker::Webhooks::Job).to receive(:perform_in)
  end

  let!(:pact) do
    td.create_pact_with_hierarchy("Foo", "1", "Bar")
      .create_consumer_version_tag("dev")
      .create_consumer_version_tag("prod")
      .create_global_verification_webhook
  end

  let(:verification_content) { load_fixture('verification.json') }
  let(:event_context) { PactBroker::Webhooks::TriggeredWebhook.last.event_context }

  context "when verifying the latest pact by URL" do
    let(:pact_url) { PactBroker::Api::PactBrokerUrls.latest_pact_url("", pact) }
    it "passes the consumer version number into the verification event context" do
      response = get(pact_url)
      publish_verification_results_url = JSON.parse(response.body)["_links"]["pb:publish-verification-results"]["href"]
      post(publish_verification_results_url, verification_content, { "CONTENT_TYPE" => "application/json" })
      expect(event_context["consumer_version_number"]).to eq "1"
    end
  end

  context "when verifying the latest pact for a tag by URL" do
    let(:pact_url) { PactBroker::Api::PactBrokerUrls.latest_pact_url("", pact) + "/dev" }
    let(:event_context) { PactBroker::Webhooks::TriggeredWebhook.last.event_context }

    it "passes the consumer version number and tag into the triggered webhook event context" do
      response = get(pact_url)
      publish_verification_results_url = JSON.parse(response.body)["_links"]["pb:publish-verification-results"]["href"]
      post(publish_verification_results_url, verification_content, { "CONTENT_TYPE" => "application/json" })
      expect(event_context).to include "consumer_version_number" => "1", "consumer_version_tags" => ["dev"]
    end
  end

  context "when verifying pacts via the pacts for verification API" do
    let(:request_body) do
      {
        consumerVersionSelectors: [ { tag: "dev", latest: true } ],
      }
    end

    let(:request_headers) do
      {
        "CONTENT_TYPE" => "application/json",
        "HTTP_ACCEPT" => "application/hal+json"
      }
    end

    let(:path) { "/pacts/provider/Bar/for-verification" }

    it "passes the consumer version number and tag into the triggered webhook event context" do
      response = post(path, request_body.to_json, request_headers)
      pact_url = JSON.parse(response.body)["_embedded"]["pacts"].first["_links"]["self"]["href"]
      response = get(pact_url)
      publish_verification_results_url = JSON.parse(response.body)["_links"]["pb:publish-verification-results"]["href"]
      post(publish_verification_results_url, verification_content, { "CONTENT_TYPE" => "application/json" })
      expect(event_context).to include "consumer_version_number" => "1", "consumer_version_tags" => ["dev"]
    end
  end
end
