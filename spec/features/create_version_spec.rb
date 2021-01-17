describe "Creating a pacticipant version" do
  let(:path) { "/pacticipants/Foo/versions/1234" }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true)}
  let(:version_hash) { { branch: "main", buildUrl: "http://build" } }

  subject { put(path, version_hash.to_json, headers) }

  it "returns a 201 response" do
    expect(subject.status).to be 201
  end

  it "returns a HAL JSON Content Type" do
    expect(subject.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
  end

  it "returns the newly created version" do
    expect(response_body).to include version_hash
  end

  context "when the version already exists" do
    before do
      td.subtract_day
        .create_consumer("Foo")
        .create_consumer_version("1234", branch: "original-branch", build_url: "original-build-url")
        .create_consumer_version_tag("dev")
    end

    let(:version_hash) { { branch: "new-branch" } }

    it "overwrites the direct properties" do
      expect(response_body[:branch]).to eq "new-branch"
      expect(response_body).to_not have_key(:buildUrl)
    end

    it "does not change the tags" do
      expect { subject }.to_not change { PactBroker::Domain::Version.for("Foo", "1234").tags }
    end

    it "does not change the created date" do
      expect { subject }.to_not change { PactBroker::Domain::Version.for("Foo", "1234").created_at }
    end
  end
end
