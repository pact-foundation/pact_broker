describe "fetching pacts to verify", pending: 'not yet implemented' do
  before do
    # td.create_pact_with_hierarchy("Foo", "1", "Bar")
    #   .create_consumer_version_tag("feat-1")
    #   .create_provider_version_tag("master")
  end
  let(:path) { "/pacts/provider/Provider/verifiable" }
  let(:query) do
    # need to provide the provider tags that will be used when publishing the
    # verification results, as whether a pact
    # is pending or not depends on which provider tag we're talking about
    # eg. if content has been verified on git branch (broker tag) feat-2,
    # it's still pending on master, and shouldn't fail the build
    {
      provider_version_tags: [{ name: "feat-2" }],
      consumer_version_tags: [
        { name: "feat-1", fallback: "master" }, # allow a fallback to be provided for the "branch mirroring" workflow
        { name: "test", required: true }, # default to optional or required??? Ron?
        { name: "prod", all: true } # by default return latest, but allow "all" to be specified for things like mobile apps
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
