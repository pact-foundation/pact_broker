describe "pacts" do
  xdescribe "POST" do

    let(:pact_content) { load_fixture('consumer-provider.json') }
    let(:path) { "/pacts" }
    let(:response_body_json) { JSON.parse(subject.body) }

    subject { post path, pact_content, {'CONTENT_TYPE' => 'application/json', 'HTTP_X_PACT_CONSUMER_VERSION' => '1.2.3' }; last_response  }

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

      it "returns a 400 Bad Request" do
        expect(subject.status).to be 400
      end

      it "returns a json body" do
        expect(subject.headers['Content-Type']).to eq "application/json"
      end

      it "returns an error message" do
        expect(response_body_json).to include error: 'message'
      end
    end
  end
end
