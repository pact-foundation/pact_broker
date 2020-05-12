describe "Creating a pacticipant version" do
  let(:path) { "/pacticipants/Foo/versions/1234" }
  let(:headers) { {'CONTENT_TYPE' => 'application/json'} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}
  let(:version_hash) { { branch: 'master', buildUrl: 'http://build' } }

  subject { patch(path, version_hash.to_json, headers) }

  it "returns a 201 response" do
    subject
    expect(last_response.status).to be 201
  end

  it "returns the Location header" do
    subject
    expect(last_response.headers['Location']).to eq "http://example.org#{path}"
  end

  it "returns a JSON Content Type" do
    subject
    expect(last_response.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
  end

  it "returns the newly created version" do
    subject
    expect(response_body).to include version_hash
  end
end
