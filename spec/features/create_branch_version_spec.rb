describe "Creating a branch version" do
  let(:path) { "/pacticipants/Foo/branches/main/versions/1234" }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { put(path, {}, headers) }

  it "returns a 201 response" do
    expect(subject.status).to be 201
  end

  it "returns a HAL JSON Content Type" do
    expect(subject.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
  end

  context "when the branch version already exists" do
    before do
      td.subtract_day
        .create_consumer("Foo")
        .create_consumer_version("1234", branch: "main")
    end

    its(:status) { is_expected.to eq 200 }
  end

  context "when the branch version does not exist" do
    its(:status) { is_expected.to eq 201 }
  end

  context "with a percentage in the version number" do
    let(:path) { "/pacticipants/foo/branches/main/versions/%25DATE%25_%25TIME%25" }

    it "returns a 201 response" do
      expect(subject.status).to be 201
      expect(PactBroker::Domain::Version.last.number).to eq "%DATE%_%TIME%"
    end
  end
end
