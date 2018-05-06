
describe "adding environment for a pacticipant version" do
  let(:path) { "/pacticipants/Foo/versions/1.2.3/environments/feat%2Fbar" }

  subject { put path, nil, {'CONTENT_TYPE' => 'application/json'}; last_response }

  context "when the pacticipant/version/tag do not exist" do
    it "creates an environment" do
      expect{ subject }.to change {
        PactBroker::Environments::Environment.where(name: 'feat/bar').count
      }.by(1)
    end
  end
end
