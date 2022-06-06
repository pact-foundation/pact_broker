describe "Deleting a branch version (removing a version from a branch)" do
  before do
    td.create_consumer("foo")
      .create_consumer_version("1234", branch: "main")
      .create_consumer_version("1234", branch: "not-main")
      .create_consumer_version("555", branch: "main")
      .create_consumer("bar")
      .create_consumer_version("1234", branch: "main")
  end

  let(:path) { "/pacticipants/foo/branches/main/versions/1234" }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { delete(path, {}, headers) }

  it "returns a 204 response" do
    expect(subject.status).to be 204
  end

  it "deletes the branch version" do
    expect { subject }.to change { PactBroker::Versions::BranchVersion.count }.by(-1)
  end

  context "when the branch version does not exist" do
    let(:path) { "/pacticipants/foo/branches/main/versions/888" }

    its(:status) { is_expected.to eq 404 }
  end
end
