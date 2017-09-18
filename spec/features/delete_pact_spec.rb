describe "Deleting a pact" do

  let(:pact_content) { load_fixture('a_consumer-a_provider.json') }
  let(:path) { "/pacts/provider/A%20Provider/consumer/A%20Consumer/version/1.2.3" }
  let(:response_body_json) { JSON.parse(subject.body) }

  subject { delete path; last_response  }

  context "when the pact exists" do
    before do
      TestDataBuilder.new
        .create_pact_with_hierarchy("A Consumer", "1.2.3", "A Provider")
        .create_webhook
        .create_triggered_webhook
        .create_deprecated_webhook_execution
    end

    it "deletes the pact" do
      expect{ subject }.to change{ PactBroker::Pacts::PactPublication.count }.by(-1)
    end

    it "returns a 204" do
      expect(subject.status).to be 204
    end
  end

  context "when the pact does not exist" do
    it "returns a 404 Not Found" do
      expect(subject.status).to be 404
    end
  end
end
