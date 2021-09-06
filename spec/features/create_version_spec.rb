describe "Creating a pacticipant version" do
  let(:path) { "/pacticipants/Foo/versions/1234" }
  let(:headers) { { "CONTENT_TYPE" => content_type } }
  let(:content_type) { "application/json" }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true)}
  let(:version_hash) do
    {
      buildUrl: "http://build",
      tags: [{ name: "foo" }, { name: "bar" }]
    }
  end

  context "with a PUT" do
    subject { put(path, version_hash.to_json, headers) }

    it "returns a 201 response" do
      expect(subject.status).to be 201
    end

    it "returns a HAL JSON Content Type" do
      expect(subject.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
    end

    it "returns the newly created version" do
      expect(response_body).to include buildUrl: "http://build"
      expect(response_body[:_embedded][:tags].size).to eq 2
    end

    it "creates the specified tags" do
      expect { subject }.to change { PactBroker::Domain::Tag.count }.by(2)
    end
  end

  context "with a PATCH" do
    let(:content_type) { "application/merge-patch+json" }

    subject { patch(path, version_hash.to_json, headers) }

    it "returns a 201 response" do
      expect(subject.status).to be 201
    end

    it "returns a HAL JSON Content Type" do
      expect(subject.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
    end

    it "returns the newly created version" do
      expect(response_body).to include buildUrl: "http://build"
      expect(response_body[:_embedded][:tags].size).to eq 2
    end

    it "creates the specified tags" do
      expect { subject }.to change { PactBroker::Domain::Tag.count }.by(2)
    end
  end
end
