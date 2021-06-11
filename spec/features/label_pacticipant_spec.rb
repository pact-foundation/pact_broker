describe "Labelling a pacticipant" do

  let(:path) { "/pacticipants/foo/labels/ios" }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }
  let(:expected_response_body) { {name: "ios"} }

  subject { put path, nil, {"CONTENT_TYPE" => "application/json"}; last_response  }

  context "when the pacticipant exists" do
    it "returns a 201 Created" do
      expect(subject.status).to be 201
    end

    it "returns a json body" do
      expect(subject.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
    end

    it "returns the label in the body" do
      expect(response_body_hash).to include expected_response_body
    end
  end
end
