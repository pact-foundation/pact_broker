describe "Get integrations dot file" do
  before do
    td.create_pact_with_hierarchy("Foo", "1", "Bar")
      .create_verification(provider_version: "2")
  end

  let(:path) { "/integrations" }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get path, nil, {"HTTP_ACCEPT" => "application/hal+json" }  }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns a json body with embedded integrations" do
    expect(JSON.parse(subject.body)["_embedded"]["integrations"]).to be_a(Array)
  end
end
