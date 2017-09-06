describe "tagging a pacticipant version" do
  let(:path) { "/pacticipants/Foo/versions/1.2.3/tags/feat%2Fbar" }

  subject { put path,nil, {'CONTENT_TYPE' => 'application/json'}; last_response }

  context "when the pacticipant/version/tag do not exist" do
    it "creates a tag" do
      expect{ subject }.to change {
        PactBroker::Domain::Tag.where(name: 'feat/bar').count
      }.by(1)
    end
  end
end
