describe "Deleting a branch (removing all versions from a branch)" do
  before do
    td.create_consumer("foo")
      .create_consumer_version("1234", branch: "main")
      .create_consumer_version("1234", branch: "not-main")
      .create_consumer_version("555", branch: "main")
      .create_consumer("bar")
      .create_consumer_version("1234", branch: "main")
  end

  let(:path) { "/pacticipants/foo/branches/main" }
  let(:headers) { {} }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { delete(path, nil, headers) }

  it "returns a 204 response" do
    expect(subject.status).to be 204
  end

  it "deletes the branch" do
    expect { subject }.to change { PactBroker::Versions::Branch.count }.by(-1)
  end

  it "does not delete the pacticipant versions" do
    expect { subject }.to_not change { PactBroker::Domain::Version.count }
  end

  context "when the branch version does not exist" do
    let(:path) { "/pacticipants/waffle/branches/main" }

    its(:status) { is_expected.to eq 404 }
  end

  context "when there is some flag to indicate that the versions should be deleted too" do
    subject { delete(path, { deleteVersions: true }, headers) }

    it "deletes the branch" do
      expect { subject }.to change { PactBroker::Versions::Branch.count }.by(-1)
    end

    it "DOES delete the pacticipant versions", pending: true do
      expect { subject }.to change { PactBroker::Domain::Version.count }.by(-2)
    end
  end
end
