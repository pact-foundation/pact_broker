describe "Publishing a pact" do

  let(:pact_content) { load_fixture('a_consumer-a_provider.json') }
  let(:path) { "/pacts/provider/A%20Provider/consumer/A%20Consumer/versions/1.2.3" }
  let(:response_body_json) { JSON.parse(subject.body) }

  subject { put path, pact_content, {'CONTENT_TYPE' => 'application/json' }; last_response  }

  context "when a pact for this consumer version does not exist" do
    it "returns a 201 Created" do
      expect(subject.status).to be 201
    end

    it "returns a json body" do
      expect(subject.headers['Content-Type']).to eq "application/hal+json;charset=utf-8"
    end

    it "returns the pact in the body" do
      expect(response_body_json).to include JSON.parse(pact_content)
    end
  end

  context "when a pact for this consumer version does exist" do

    before do
      TestDataBuilder.new.create_pact_with_hierarchy("A Consumer", "1.2.3", "A Provider").and_return(:pact)
    end

    it "returns a 200 Success" do
      expect(subject.status).to be 200
    end

    it "returns an application/json Content-Type" do
      expect(subject.headers['Content-Type']).to eq "application/hal+json;charset=utf-8"
    end

    it "returns the pact in the response body" do
      expect(response_body_json).to include JSON.parse(pact_content)
    end
  end

  context "when the pacticipant names in the path do not match those in the pact" do
    let(:path) { "/pacts/provider/Another%20Provider/consumer/A%20Consumer/version/1.2.3" }

    it "returns a json error response" do
      expect(subject).to be_a_json_error_response "does not match"
    end
  end

  context "when the pacticipant name is an almost duplicate of an existing pacticipant name" do
    before do
      TestDataBuilder.new.create_pacticipant("A Provider Service")
    end

    context "when duplicate checking is on" do
      before do
        PactBroker.configuration.check_for_potential_duplicate_pacticipant_names = true
      end

      it "returns a 409" do
        expect(subject.status).to eq 409
      end
    end

    context "when duplicate checking is off" do
      before do
        PactBroker.configuration.check_for_potential_duplicate_pacticipant_names = false
      end

      it "returns a 201" do
        expect(subject.status).to eq 201
      end
    end
  end
end
