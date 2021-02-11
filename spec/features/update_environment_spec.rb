describe "Updating an environment" do
  before do
    td.create_environment("test", uuid: "1234", contacts: [ { name: "Foo" } ] )
  end
  let(:path) { "/environments/1234" }
  let(:headers) { {'CONTENT_TYPE' => 'application/json'} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}
  let(:environment_hash) do
    {
      name: "test",
      displayName: "Testing"
    }
  end

  subject { put(path, environment_hash.to_json, headers) }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns the updated environment" do
    subject
    expect(response_body[:displayName]).to eq "Testing"
    expect(response_body[:contacts]).to be nil
  end

  context "when the environment doesn't exist" do
    let(:path) { "/environments/5678" }

    it "returns a 404" do
      expect(subject.status).to eq 404
    end
  end

  context "with invalid params" do
    let(:environment_hash) { {} }

    it "returns a 400 response" do
      expect(subject.status).to be 400
      expect(response_body[:errors]).to_not be nil
    end
  end
end
