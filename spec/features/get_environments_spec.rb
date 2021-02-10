describe "Get all environments" do
  before do
    td.create_environment("test", label: "Test", uuid: "1234", owners: [ { name: "Foo" } ] )
      .create_environment("prod", label: "Production", uuid: "5678", owners: [ { name: "Foo" } ] )
  end
  let(:path) { "/environments" }
  let(:headers) { {'HTTP_ACCEPT' => 'application/hal+json'} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}

  subject { get(path, nil, headers) }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns the environments" do
    subject
    expect(response_body[:_embedded][:environments].size).to be 2
  end
end
