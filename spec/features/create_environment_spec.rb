describe "Creating an environment" do
  let(:path) { "/environments/test" }
  let(:headers) { {'CONTENT_TYPE' => 'application/json'} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}
  let(:environment_hash) do
    {
      label: "Test",
      owners: [ { name: "Team Awesome", contacts: ["awesome@company.org"] } ]
    }
  end

  subject { put(path, environment_hash.to_json, headers) }

  it "returns a 201 response" do
    subject
    expect(last_response.status).to be 201
  end

  it "returns the Location header" do
    subject
    expect(last_response.headers['Location']).to eq 'http://example.org/environments/test'
  end

  it "returns a JSON Content Type" do
    subject
    expect(last_response.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
  end

  it "returns the newly created environment" do
    subject
    expect(response_body).to include environment_hash.merge(name: "test")
  end
end
