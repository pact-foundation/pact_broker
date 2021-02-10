describe "Creating an environment" do
  let(:path) { "/environments" }
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}
  let(:environment_hash) do
    {
      name: "test",
      label: "Test",
      owners: [ { name: "Team Awesome", contacts: ["awesome@company.org"] } ]
    }
  end

  subject { post(path, environment_hash.to_json, headers) }

  it "returns a 201 response" do
    subject
    expect(last_response.status).to be 201
  end

  it "returns the Location header" do
    subject
    expect(last_response.headers["Location"]).to start_with "http://example.org/environments/"
  end

  it "returns a JSON Content Type" do
    subject
    expect(last_response.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
  end

  it "returns the newly created environment" do
    subject
    expect(response_body).to include environment_hash.merge(name: "test")
    expect(response_body[:uuid]).to_not be nil
  end
end
