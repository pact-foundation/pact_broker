require "webmock/rspec"
require "rack/pact_broker/database_transaction"

describe "Execute a webhook" do
  before do
    td.create_pact_with_hierarchy("Foo", "1", "Bar")
      .create_webhook(method: "POST", body: "${pactbroker.pactUrl}")
  end

  let(:path) { "/webhooks/#{td.webhook.uuid}/execute" }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}

  subject { post(path) }

  context "when the execution is successful" do
    let!(:request) do
      stub_request(:post, /http/).with(body: expected_webhook_url).to_return(:status => 200, body: response_body)
    end

    let(:expected_webhook_url) { %r{http://example.org/pacts/provider/Bar/consumer/Foo/pact-version/.*/metadata/.*} }
    let(:response_body) { "webhook-response-body" }

    it "performs the HTTP request" do
      subject
      expect(request).to have_been_made
    end

    it "returns a 200 response" do
      expect(subject.status).to be 200
    end

    it "does not save a TriggeredWebhook" do
      expect { subject }.to_not change { PactBroker::Webhooks::TriggeredWebhook.count }
    end

    it "does not save a WebhookExecution" do
      expect { subject }.to_not change { PactBroker::Webhooks::Execution.count }
    end

    context "when a webhook host whitelist is not configured" do
      before do
        allow(PactBroker.configuration).to receive(:show_webhook_response?).and_return(false)
      end

      it "does not show any response details" do
        expect(subject.body).to_not include response_body
      end
    end

    context "when a webhook host whitelist is configured" do
      before do
        allow(PactBroker.configuration).to receive(:show_webhook_response?).and_return(true)
      end

      it "includes response details" do
        expect(subject.body).to include response_body
      end
    end
  end

  context "when an error occurs", no_db_clean: true do
    let(:app) { Rack::PactBroker::DatabaseTransaction.new(PactBroker::API, PactBroker::DB.connection) }

    let!(:request) do
      stub_request(:post, /http/).to_raise(Errno::ECONNREFUSED)
    end

    before do
      PactBroker::TestDatabase.truncate
      td.create_pact_with_hierarchy("Some Consumer", "1", "Some Provider")
        .create_webhook(method: "POST")
    end

    after do
      PactBroker::TestDatabase.truncate
    end

    subject { post(path) }

    it "returns a 200 response" do
      expect(subject.status).to be 200
    end

    it "does not save a TriggeredWebhook" do
      expect { subject }.to_not change { PactBroker::Webhooks::TriggeredWebhook.count }
    end

    it "does not save a WebhookExecution" do
      expect { subject }.to_not change { PactBroker::Webhooks::Execution.count }
    end
  end
end
