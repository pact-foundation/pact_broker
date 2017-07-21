describe "Deleting a label" do

  before do
    TestDataBuilder.new
      .create_pacticipant("foo")
      .create_label("ios")
      .create_label("consumer")
      .create_pacticipant("bar")
      .create_label("ios")
      .create_label("consumer")
  end

  let(:path) { "/pacticipants/foo/labels/ios" }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }
  let(:expected_response_body) { {name: 'ios'} }

  subject { delete path; last_response  }

  context "when the label exists" do
    it "returns a 204 No Content" do
      expect(subject.status).to be 204
    end

    it "deletes the label" do
      expect { subject }.to change { PactBroker::Domain::Label.count }.by(-1)
    end
  end
end
