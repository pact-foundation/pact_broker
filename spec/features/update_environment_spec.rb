describe "Updating an environment" do
  before do
    td.create_environment("test", uuid: "1234", owners: [ { name: "Foo" } ] )
  end
  let(:path) { "/environments/1234" }
  let(:headers) { {'CONTENT_TYPE' => 'application/json'} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}
  let(:environment_hash) do
    {
      label: "Testing"
    }
  end

  subject { put(path, environment_hash.to_json, headers) }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns the updated environment" do
    subject
    expect(response_body[:label]).to eq "Testing"
    expect(response_body[:owners]).to be nil
  end
end
