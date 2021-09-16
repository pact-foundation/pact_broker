RSpec.describe "triggering a webhook for a pact publication" do
  before do
    td.create_global_webhook(event_names: ["contract_published"], body: { "provider_version" => "${pactbroker.providerVersionNumber}"})
  end

  let(:pact_content) { td.random_json_content("Foo", "Bar") }

  let!(:request) do
    stub_request(:post, /http/).with(body: expected_webhook_body).to_return(:status => 200)
  end

  let(:database_connector) { ->(&block) { block.call } }

  subject { put("/pacts/provider/Bar/consumer/Foo/version/2", pact_content, { "CONTENT_TYPE" => "application/json", "pactbroker.database_connector" => database_connector}) }

  context "when there is a verification from the main branch of the provider" do
    before do
      td.create_consumer("Foo")
        .create_provider("Bar", main_branch: "main")
        .create_consumer_version("1")
        .create_pact(json_content: pact_content)
        .create_verification(provider_version: "1", branch: "main")
        .create_verification(provider_version: "2", branch: "feat/x", number: 2)
    end

    let(:expected_webhook_body) { { provider_version: "1"}.to_json }

    it "uses that in the webhook" do
      subject
      expect(request).to have_been_made
    end
  end

  context "when there is not a verification from the main branch of the provider" do
    before do
      td.create_consumer("Foo")
        .create_provider("Bar", main_branch: "main")
        .create_consumer_version("1")
        .create_pact(json_content: pact_content)
        .create_verification(provider_version: "1", branch: "feat/y")
        .create_verification(provider_version: "2", branch: "feat/x", number: 2)
    end

    let(:expected_webhook_body) { { provider_version: "2"}.to_json }

    it "uses the latest verification in the webhook" do
      subject
      expect(request).to have_been_made
    end
  end
end
