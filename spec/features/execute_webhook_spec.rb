require 'support/test_data_builder'
require 'webmock/rspec'
require 'rack/pact_broker/database_transaction'

describe "Execute a webhook" do

  let(:td) { TestDataBuilder.new }

  before do
    td.create_pact_with_hierarchy("Some Consumer", "1", "Some Provider")
      .create_webhook(method: 'POST')
  end

  let(:path) { "/webhooks/#{td.webhook.uuid}/execute" }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}

  subject { post path; last_response }

  context "when the execution is successful" do
    let!(:request) do
      stub_request(:post, /http/).to_return(:status => 200)
    end

    it "performs the HTTP request" do
      subject
      expect(request).to have_been_made
    end

    it "returns a 200 response" do
      puts subject.body
      expect(subject.status).to be 200
    end

    it "saves a TriggeredWebhook" do
      expect { subject }.to change { PactBroker::Webhooks::TriggeredWebhook.count }.by(1)
    end

    it "saves a WebhookExecution" do
      expect { subject }.to change { PactBroker::Webhooks::Execution.count }.by(1)
    end
  end

  context "when an error occurs", no_db_clean: true do
    let(:app) { Rack::PactBroker::DatabaseTransaction.new(PactBroker::API, PactBroker::DB.connection) }

    let!(:request) do
      stub_request(:post, /http/).to_raise(Errno::ECONNREFUSED)
    end

    before do
      PactBroker::Database.truncate
      td.create_pact_with_hierarchy("Some Consumer", "1", "Some Provider")
        .create_webhook(method: 'POST')
    end

    after do
      PactBroker::Database.truncate
    end

    subject { post path; last_response }

    it "returns a 500 response" do
      expect(subject.status).to be 500
    end

    it "saves a TriggeredWebhook" do
      expect { subject }.to change { PactBroker::Webhooks::TriggeredWebhook.count }.by(1)
    end

    it "saves a WebhookExecution" do
      expect { subject }.to change { PactBroker::Webhooks::Execution.count }.by(1)
    end
  end
end
