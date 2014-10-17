describe "pacts/provider/:provider/consumer/:consumer/version/:version" do
  describe "PUT" do

    let(:pact_content) { load_fixture('consumer-provider.json') }
    let(:path) { "/pacts/provider/A%20Provider/consumer/A%20Consumer/version/1.2.3" }
    let(:response_body_json) { JSON.parse(subject.body) }

    subject { put path, pact_content, {'CONTENT_TYPE' => 'application/json' }; last_response  }

    context "when the pact does not exist" do
      it "returns a 201 Created" do
        expect(subject.status).to be 201
      end

      it "returns a json body" do
        expect(subject.headers['Content-Type']).to eq "application/json"
      end

      it "returns the pact in the body" do
        expect(response_body_json).to include JSON.parse(pact_content)
      end
    end

    context "when the pact does exist" do

      before do
        ProviderStateBuilder.new.create_pact_with_hierarchy "A Consumer", "1.2.3", "A Provider"
      end

      it "returns a 200 Success" do
        expect(subject.status).to be 200
      end

      it "returns a json body" do
        expect(subject.headers['Content-Type']).to eq "application/json"
      end

      it "returns the pact in the body" do
        expect(response_body_json).to include JSON.parse(pact_content)
      end
    end

    context "when the pacticipant names in the path do not match those in the pact" do
      let(:path) { "/pacts/provider/Another%20Provider/consumer/A%20Consumer/version/1.2.3" }

      it "returns a json error response" do
        expect(subject).to be_a_json_error_response "does not match"
      end
    end

    context "when the pact is another type of CDC that doesn't have the Consumer or Provider names in the expected places" do
      let(:pact_content) { {}.to_json }

      it "accepts the un-pact Pact" do
        expect(subject.status).to be 201
      end
    end
  end
end