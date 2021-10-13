RSpec.describe "publishing a pact using the all in one endpoint" do
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
          :content => encoded_contract,
          :onConflict => "overwrite",
        }
      ]
    }
  end
  let(:rack_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json" } }
  let(:contract) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [] }.to_json }
  let(:encoded_contract) { Base64.strict_encode64(contract) }
  let(:path) { "/contracts/publish" }

  subject { post(path, request_body_hash.to_json, rack_headers) }

  it { is_expected.to be_a_hal_json_success_response }

  it "creates a pact" do
    expect { subject }.to change { PactBroker::Pacts::PactPublication.count }.by(1)
    expect(PactBroker::Pacts::PactVersion.last.content).to eq contract
  end

  context "with a validation error" do
    before do
      request_body_hash.delete(:pacticipantName)
    end

    it { is_expected.to be_a_json_error_response("missing") }
  end

  context "with a conflicting pact" do
    before do
      allow(PactBroker.configuration).to receive(:allow_dangerous_contract_modification).and_return(false)
      td.create_pact_with_hierarchy("Foo", "1", "Bar")
    end

    its(:status) { is_expected.to eq 409 }

    it "returns notices" do
      expect(JSON.parse(subject.body)["notices"]).to be_a(Array)
    end

    it "returns errors" do
      contract_errors = JSON.parse(subject.body)["errors"]["contracts"]
      expect(contract_errors).to be_a(Array)
      expect(contract_errors.size).to eq 1
    end
  end
end
