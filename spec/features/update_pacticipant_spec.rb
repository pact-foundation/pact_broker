xdescribe "Publishing a pact" do

  let(:request_body) { load_fixture('update_pacticipant.json') }
  let(:path) { "/pacticipants/Some%20Consumer" }
  let(:response_body_json) { JSON.parse(subject.body) }

  subject { patch path, request_body, {'CONTENT_TYPE' => 'application/json-patch+json' }; last_response  }

  context "when the pacticipant exists" do
    it "returns a 200 OK" do
      expect(subject.status).to be 201
    end

    it "returns a json body with the updated pacticipant" do
      expect(subject.headers['Content-Type']).to eq "application/json"
    end

  end

  context "when the pacticipant does not exist" do
    it "returns a 404" do
      expect(subject.status).to be 404
    end
  end

end
