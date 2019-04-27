describe "fetching pacts to verify", pending: 'not yet implemented' do
  before do
    # td.create_pact_with_hierarchy("Foo", "1", "Bar")
    #   .create_consumer_version_tag("feat-1")
    #   .create_provider_version_tag("master")
  end
  let(:path) { "/pacts/provider/Provider/verifiable" }
  let(:query) do
    {
      provider_version_tags: [{ name: "feat-2" }],
      consumer_version_tags: [
        { name: "feat-1", fallback: "master" },
        { name: "test", required: true },
        { name: "prod", all: true }
      ]
    }
  end
  let(:rack_env) { { 'HTTP_ACCEPT' => 'application/hal+json' } }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path, query, rack_env) }

  it "returns a 200 HAL JSON response" do
    expect(subject).to be_a_hal_json_success_response
  end

  it "returns a list of links to the pacts" do
    expect(response_body_hash[:_links][:'pb:pacts']).to be_instance_of(Array)
  end

  it "indicates whether a pact is pending or not"
end
