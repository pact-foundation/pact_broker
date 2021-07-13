describe "Creating a tag" do
  let(:path) { "/pacticipants/Foo/versions/1234/tags/foo" }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true)}

  subject { put(path, {}, headers) }

  it "returns a 201 response" do
    expect(subject.status).to be 201
  end

  it "returns a HAL JSON Content Type" do
    expect(subject.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
  end

  it "returns the newly created tag" do
    expect(response_body).to include name: "foo"
  end

  context "when the tag already exists" do
    before do
      td.subtract_day
        .create_consumer("Foo")
        .create_consumer_version("1234")
        .create_consumer_version_tag("foo")
    end

    it "returns a 200 response" do
      expect(subject.status).to be 200
    end
  end

  context "when there is an envionment with a matching name" do
    before do
      td.create_environment("foo")
    end

    it "creates a deployed version" do
      expect { subject }.to change { PactBroker::Deployments::DeployedVersion.count }.by(1)
    end
  end
end
