describe "Publishing a pact" do

  let(:request_body) { {'repositoryUrl' => 'http://foo'} }
  let(:path) { "/pacticipants/Some%20Consumer" }
  let(:response_body_json) { JSON.parse(subject.body) }

  subject { patch path, request_body.to_json, {'CONTENT_TYPE' => 'application/json' }; last_response  }

  context "when the pacticipant exists" do

    before do
      TestDataBuilder.new.create_pacticipant("Some Consumer")
    end
    it "returns a 200 OK" do
      puts subject.body unless subject.status == 200
      expect(subject.status).to be 200
    end

    it "returns a json body with the updated pacticipant" do
      expect(subject.headers['Content-Type']).to eq "application/hal+json;charset=utf-8"
    end
  end
end
