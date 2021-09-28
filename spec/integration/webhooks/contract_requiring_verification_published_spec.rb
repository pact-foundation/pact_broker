RSpec.describe "triggering a contract_requiring_verification_published webhook for a contract publication" do
  before do
    td.create_global_webhook(event_names: ["contract_requiring_verification_published"], body: webhook_body_template)
      .create_environment("test")
      .create_provider("Bar", main_branch: "main")
      .create_provider_version("1", branch: "main")
  end

  let(:webhook_body_template) do
    {
      "provider_version_number" => "${pactbroker.providerVersionNumber}",
      "provider_version_descriptions" => "${pactbroker.providerVersionDescriptions}"
    }
  end

  let(:expected_webhook_body) do
    {
      provider_version_number: "1",
      provider_version_descriptions: a_kind_of(String)
    }
  end

  let(:request_body_hash) do
    {
      :pacticipantName => "Foo",
      :pacticipantVersionNumber => "1",
      :branch => "main",
      :tags => ["a", "b"],
      :buildUrl => "http://ci/builds/1234",
      :contracts => [
        {
          :consumerName => "Foo",
          :providerName => "Bar",
          :specification => "pact",
          :contentType => "application/json",
          :content => encoded_contract
        }
      ]
    }
  end

  let(:rack_headers) do
    {
      "CONTENT_TYPE" => "application/json",
      "HTTP_ACCEPT" => "application/hal+json",
      "pactbroker.database_connector" => database_connector}
  end

  let(:contract) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [] }.to_json }
  let(:encoded_contract) { Base64.strict_encode64(contract) }
  let(:path) { "/contracts/publish" }

  let!(:request) do
    stub_request(:post, /http/).to_return(:status => 200)
  end

  subject { post(path, request_body_hash.to_json, rack_headers) }

  let(:database_connector) { ->(&block) { block.call } }

  it { is_expected.to be_a_hal_json_success_response }

  it "passes through the correct parameters to the webhook" do
    subject
    expect(a_request(:post, /http/).with(body: expected_webhook_body)).to have_been_made
  end
end
