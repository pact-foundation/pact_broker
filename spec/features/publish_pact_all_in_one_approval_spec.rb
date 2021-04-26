require 'pact_broker/hash_refinements'

RSpec.describe "publishing a pact using the all in one endpoint" do
  using PactBroker::HashRefinements
  # TODO merge branches
  let(:request_body_hash) do
    {
      :pacticipantName => "Foo",
      :versionNumber => "1",
      :tags => ["a", "b"],
      :branch => "main",
      :buildUrl => "http://ci/builds/1234",
      :contracts => [
        {
          :consumerName => "Foo",
          :providerName => "Bar",
          :specification => "pact",
          :contentType => "application/json",
          :content => encoded_contract,
          :writeMode => "overwrite",
        }
      ]
    }
  end
  let(:rack_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json" } }
  let(:contract) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [] }.to_json }
  let(:encoded_contract) { Base64.strict_encode64(contract) }
  let(:path) { "/contracts/publish" }
  let(:fixture) do
    {
      request: { body: request_body_hash },
      response: { status: subject.status, headers: subject.headers.without("Date", "Server"), body: JSON.parse(subject.body)}
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
end
