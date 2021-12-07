RSpec.describe "triggering a webhook for verification publication" do
  before do
    td.create_global_webhook(event_names: ["provider_verification_published"], body: webhook_body_template)
      .create_pact_with_hierarchy("Foo", "1", "Bar")
  end

  let(:webhook_body_template) do
    {
      "build_url" => "${pactbroker.buildUrl}"
    }
  end

  let(:expected_webhook_body) do
    {
      build_url: "http://ci/builds/1234"
    }
  end

  let(:path) { "/pacts/provider/Bar/consumer/Foo/pact-version/#{td.and_return(:pact).pact_version_sha}/verification-results" }
  let(:verification_content) { load_json_fixture("verification.json").merge("buildUrl" => "http://ci/builds/1234") }

  let(:rack_headers) do
    {
      "CONTENT_TYPE" => "application/json",
      "HTTP_ACCEPT" => "application/hal+json",
      "pactbroker.database_connector" => database_connector
    }
  end

  let!(:request) do
    stub_request(:post, /http/).to_return(:status => 200)
  end

  subject { post(path, verification_content.to_json, rack_headers) }

  let(:database_connector) { ->(&block) { block.call } }

  it { is_expected.to be_a_hal_json_created_response }

  it "passes through the correct parameters to the webhook" do
    subject
    expect(a_request(:post, /http/).with(body: expected_webhook_body)).to have_been_made
  end
end
