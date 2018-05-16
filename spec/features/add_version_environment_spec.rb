describe "adding environment for a pacticipant version" do
  before do
    PactBroker.configuration.environments = ["production"]
  end

  let(:path) { "/pacticipants/Foo/versions/1.2.3/environments/production" }

  subject { put path, nil, {'CONTENT_TYPE' => 'application/json'}; last_response }

  context "when the pacticipant/version/environment do not exist" do
    it "creates an environment" do
      expect{ subject }.to change {
        PactBroker::Environments::Environment.where(name: 'production').count
      }.by(1)
    end
  end

  context "when the environment name is not in the list of allowed environments" do
    let(:path) { "/pacticipants/Foo/versions/1.2.3/environments/prod" }

    it "returns an error" do
      expect(subject.status).to eq 400
    end
  end
end
