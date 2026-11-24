RSpec.shared_context "publishing Pact Janus contracts" do
  let(:features) { { janus: true } }
  let(:rack_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json" } }
  let(:contract) { load_json_fixture("janus-contract.json") }

  before do
    allow(PactBroker.configuration).to receive(:features).and_return(features)
    # the default everywhere but this test suite
    PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = true
  end

  def publish(version, content, specification: "janus")
    body = {
      pacticipantName: "Foo",
      pacticipantVersionNumber: version,
      branch: "main",
      contracts: [
        {
          consumerName: "Foo",
          providerName: "Bar",
          specification: specification,
          contentType: "application/json",
          content: Base64.strict_encode64(content.to_json)
        }
      ]
    }
    post("/contracts/publish", body.to_json, rack_headers)
  end

  def events_detected(response)
    JSON.parse(response.body)["notices"].collect { |notice| notice["text"] }.grep(/Events detected/).join
  end

  def with_changed_interaction(contract)
    changed = JSON.parse(contract.to_json)
    changed["interactions"].first["parts"]["request"]["path"]["example"] = "/orders/43"
    changed
  end

  def without_ids(content)
    content.merge("interactions" => content["interactions"].collect { |i| i.reject { |key, _| key == "_id" } })
  end
end

RSpec.describe "publishing a Pact Janus contract", validate_oas: true do
  include_context "publishing Pact Janus contracts"

  context "with the janus feature on" do
    it "is stored as a pact version, with the contract as its content" do
      expect(publish("1", contract)).to be_a_hal_json_success_response
      expect(PactBroker::Pacts::PactPublication.count).to eq 1
      expect(without_ids(JSON.parse(PactBroker::Pacts::PactVersion.last.content))).to eq contract
    end

    it "records its emissive interaction as a message and the other as an HTTP interaction" do
      publish("1", contract)
      pact_version = PactBroker::Pacts::PactVersion.last
      expect(pact_version.messages_count).to eq 1
      expect(pact_version.interactions_count).to eq 1
      expect(pact_version.has_messages).to be true
      expect(pact_version.has_http_interactions).to be true
    end

    it "fires contract_content_changed when it is first published" do
      expect(events_detected(publish("1", contract))).to include "contract_content_changed"
    end

    it "is deduplicated: a republish with only its metadata changed is the same pact version, and fires nothing" do
      publish("1", contract)
      response = publish("2", contract.merge("metadata" => { "created" => "2026-11-16T00:00:00Z" }))
      expect(PactBroker::Pacts::PactVersion.count).to eq 1
      expect(PactBroker::Pacts::PactPublication.count).to eq 2
      expect(events_detected(response)).to_not include "contract_content_changed"
    end

    it "is the same pact version whether it was published as janus or as pact" do
      publish("1", contract, specification: "pact")
      publish("2", contract)
      expect(PactBroker::Pacts::PactVersion.count).to eq 1
    end

    it "is a new pact version, and fires contract_content_changed, when an interaction changes" do
      publish("1", contract)
      response = publish("2", with_changed_interaction(contract))
      expect(PactBroker::Pacts::PactVersion.count).to eq 2
      expect(events_detected(response)).to include "contract_content_changed"
    end

    it "refuses a pact published as a Janus contract" do
      response = publish("1", load_json_fixture("consumer-provider.json").merge("consumer" => { "name" => "Foo" }, "provider" => { "name" => "Bar" }))
      expect(response.status).to eq 400
      expect(response.body).to include "must be a Janus contract"
      expect(PactBroker::Pacts::PactPublication.count).to eq 0
    end
  end

  context "with the janus feature off" do
    let(:features) { {} }

    it "refuses the specification as it did before the feature existed, and stores nothing" do
      response = publish("1", contract)
      expect(response.status).to eq 400
      expect(JSON.parse(response.body)["errors"]["contracts"]).to eq ["specification must be one of: pact (at index 0)"]
      expect(PactBroker::Pacts::PactPublication.count).to eq 0
      expect(PactBroker::Domain::Version.count).to eq 0
    end

    it "stores a contract published as a pact, as it always has, with every interaction an HTTP interaction" do
      expect(publish("1", contract, specification: "pact")).to be_a_hal_json_success_response
      pact_version = PactBroker::Pacts::PactVersion.last
      expect(pact_version.messages_count).to eq 0
      expect(pact_version.interactions_count).to eq 2
    end
  end
end

# The diff and provider-state resources are not in the OAS document
RSpec.describe "reading a published Pact Janus contract" do
  include_context "publishing Pact Janus contracts"

  it "is diffed against the previous distinct version" do
    publish("1", contract)
    publish("2", with_changed_interaction(contract))
    diff = get("/pacts/provider/Bar/consumer/Foo/version/2/diff/previous-distinct")
    expect(diff.status).to eq 200
    expect(diff.body).to include "/orders/42"
    expect(diff.body).to include "/orders/43"
  end

  it "gives the provider its states" do
    publish("1", contract)
    states = JSON.parse(get("/pacts/provider/Bar/provider-states").body)["providerStates"]
    expect(states.collect { |state| state["name"] }).to eq ["an order exists", "an order was shipped"]
    expect(states.first["params"]).to eq("id" => "42")
  end

  it "is served with an _id on each interaction, which a Janus verifier ignores" do
    publish("1", contract)
    served = JSON.parse(get("/pacts/provider/Bar/consumer/Foo/version/1").body)
    expect(served["interactions"].collect { |i| i["_id"] }).to all(be_a(String))
    expect(served["$format"]).to eq "janus-contract/1"
  end
end
