describe "fetching pacts to verify" do
  before do
    td.create_pact_with_hierarchy("Foo", "1", "Bar")
      .create_consumer_version_tag("feat-1")
  end
  let(:path) { "/pacts/provider/Bar/verifiable" }
  let(:query) do
    # need to provide the provider tags that will be used when publishing the
    # verification results, as whether a pact
    # is pending or not depends on which provider tag we're talking about
    # eg. if content has been verified on git branch (broker tag) feat-2,
    # it's still pending on master, and shouldn't fail the build
    {
      protocol: "http1", # other option is "message"
      include_other_pending: true, # whether or not to include pending pacts not already specified by the consumer_version_tags('head' pacts that have not yet been successfully verified)
      provider_version_tags: ["feat-2"], # the provider tags that will be applied to this app version when the results are published
      consumer_version_selectors: [
        { tag: "feat-1", fallback: "master" }, # allow a fallback to be provided for the "branch mirroring" workflow
        { tag: "test", required: true }, # default to optional or required??? Ron?
        { tag: "prod", all: true } # by default return latest, but allow "all" to be specified for things like mobile apps
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
    expect(response_body_hash[:_embedded][:'pacts']).to be_instance_of(Array)
  end

  describe "this is checking too much for such a high level spec, but it's important that this works correctly!" do
    context "when the pact has not been verified by a version with the given provider tags before" do
      it "is pending" do
        expect(response_body_hash[:_embedded][:pacts].first[:pending]).to be true
      end
    end

    context "when the pact has successfully been verified by a version with the given provider tags before" do
      before do
        td.create_verification(provider_version: "23", tag_names: ["feat-2"])
      end

      it "is not pending" do
        expect(response_body_hash[:_embedded][:pacts].first[:pending]).to be false
      end
    end
  end
end
