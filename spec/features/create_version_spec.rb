describe "Creating a pacticipant version" do
  let(:path) { "/pacticipants/Foo/versions/1234" }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true)}
  let(:version_hash) do
    {
      branch: "main",
      buildUrl: "http://build",
      tags: [{ name: "foo" }, { name: "bar" }]
    }
  end

  subject { put(path, version_hash.to_json, headers) }

  it "returns a 201 response" do
    expect(subject.status).to be 201
  end

  it "returns a HAL JSON Content Type" do
    expect(subject.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
  end

  it "returns the newly created version" do
    expect(response_body).to include branch: "main", buildUrl: "http://build"
    expect(response_body[:_embedded][:tags].size).to eq 2
  end

  it "creates the specified tags" do
    expect { subject }.to change { PactBroker::Domain::Tag.count }.by(2)
  end

  context "when the version already exists" do
    before do
      td.subtract_day
        .create_consumer("Foo")
        .create_consumer_version("1234", branch: "original-branch", build_url: "original-build-url")
        .create_consumer_version_tag("dev")
    end

    context "when the branch is attempted to be changed" do
      let(:version_hash) { { branch: "new-branch" } }

      its(:status) { is_expected.to eq 409 }
    end

    context "when the branch is not attempted to be changed" do
      let(:version_hash) { { branch: "original-branch" } }

      it "overwrites the direct properties and blanks out any unprovided ones" do
        expect(response_body[:branch]).to eq "original-branch"
        expect(response_body).to_not have_key(:buildUrl)
      end
    end

    context "when no tags are specified" do
      it "does not change the tags" do
        expect { subject }.to_not change { PactBroker::Domain::Version.for("Foo", "1234").tags }
      end
    end

    context "when tags are specified" do
      let(:version_hash) { { branch: "original-branch", tags: [ { name: "main" }] } }

      it "overwrites the tags" do
        expect(response_body[:_embedded][:tags].size).to eq 1
        expect(response_body[:_embedded][:tags].first[:name]).to eq "main"
      end
    end

    it "does not change the created date" do
      expect { subject }.to_not change { PactBroker::Domain::Version.for("Foo", "1234").created_at }
    end
  end
end
