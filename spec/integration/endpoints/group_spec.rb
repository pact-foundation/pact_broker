describe "/groups/{pacticipant-name}" do

  let(:app) { PactBroker::API }

  describe "GET" do
    before do
      TestDataBuilder.new.create_pact_with_hierarchy("Consumer", "1.2.3", "Provider").and_return(:pact)
      get "/groups/Consumer"
    end

    it "returns a success response" do
      expect(last_response.status).to eq 200
    end

    it "returns a body" do
      expect(last_response.body).to_not be_nil
    end
  end
end
