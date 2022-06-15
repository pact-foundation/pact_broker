describe "Creating a pacticipant" do
  let(:path) { "/pacticipants" }
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}
  let(:pacticipant_hash) do
    {
      name: "Foo Thing",
      mainBranch: "main",
      repositoryUrl: "http://url",
      repositoryName: "foo-thing",
      repositoryNamespace: "some-group"
    }
  end

  subject { post(path, pacticipant_hash.to_json, headers) }

  it "returns a 201 response" do
    subject
    expect(last_response.status).to be 201
  end

  it "returns the Location header" do
    subject
    expect(last_response.headers["Location"]).to eq "http://example.org/pacticpants/Foo%20Thing"
  end

  it "returns a JSON Content Type" do
    subject
    expect(last_response.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
  end

  it "returns the newly created pacticipant" do
    subject
    expect(response_body).to include pacticipant_hash
  end

  context "with an empty JSON document" do
    let(:pacticipant_hash) { {} }

    its(:status) { is_expected.to eq 400 }
  end
end
