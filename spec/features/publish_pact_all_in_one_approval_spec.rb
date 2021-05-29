RSpec.describe "publishing a pact using the all in one endpoint" do
  # TODO merge branches
  let(:request_body_hash) do
    {
      :pacticipantName => "Foo",
      :pacticipantVersionNumber => "1",
      :branch => branch,
      :tags => ["a", "b"],
      :buildUrl => "http://ci/builds/1234",
      :contracts => [
        {
          :consumerName => "Foo",
          :providerName => "Bar",
          :specification => "pact",
          :contentType => "application/json",
          :content => encoded_contract,
          :onConflict => "overwrite",
        }
      ]
    }
  end
  let(:rack_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json" } }
  let(:contract) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [] }.to_json }
  let(:branch) { "main" }
  let(:encoded_contract) { Base64.strict_encode64(contract) }
  let(:path) { "/contracts/publish" }
  let(:fixture) do
    {
      request: { path: path, headers: rack_env_to_http_headers(rack_headers), body: request_body_hash },
      response: { status: subject.status, headers: determinate_headers(subject.headers), body: JSON.parse(subject.body)}
    }
  end

  subject { post(path, request_body_hash.to_json, rack_headers) }

  it { is_expected.to be_a_hal_json_success_response }

  context "with no webhooks" do
    it { Approvals.verify(fixture, :name => "publish_contract_nothing_exists", format: :json) }
  end

  context "with a webhooks that gets triggered" do
    before do
      allow(PactBroker::Webhooks::TriggerService).to receive(:next_uuid).and_return("1234")
      td.create_global_webhook(description: "foo webhook")
    end

    it { Approvals.verify(fixture, :name => "publish_contract_nothing_exists_with_webhook", format: :json) }
  end

  context "with a validation error" do
    before do
      request_body_hash.delete(:pacticipantVersionNumber)
    end

    it { Approvals.verify(fixture, :name => "publish_contract_with_validation_error", format: :json) }
  end

  context "when a verification already exists for the consumer/provider" do
    before do
      td.create_pact_with_verification("Foo", "1", "Bar", "2")
    end

    it { Approvals.verify(fixture, :name => "publish_contract_verification_already_exists", format: :json) }
  end

  context "with no branch set" do
    let(:branch) { nil }

    it { Approvals.verify(fixture, :name => "publish_contract_no_branch", format: :json) }
  end
end
