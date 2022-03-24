RSpec.describe "base_equality_only_on_content_that_affects_verification_results" do
  let(:json_content_1) { load_fixture("foo-bar.json") }
  let(:json_content_2) do
    pact_hash = load_json_fixture("foo-bar.json")
    pact_hash["interactions"] = pact_hash["interactions"].reverse
    pact_hash.to_json
  end
  let(:base_equality_only_on_content_that_affects_verification_results) { true }

  before do
    PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = base_equality_only_on_content_that_affects_verification_results
    td.publish_pact(consumer_name: "Foo", consumer_version_number: "1", provider_name: "Bar", json_content: json_content_1)
      .publish_pact(consumer_name: "Foo", consumer_version_number: "2", provider_name: "Bar", json_content: json_content_2)
  end

  context "when a pact is published with a different order of interactions to a previous version, but which is otherwise the same" do
    context "when base_equality_only_on_content_that_affects_verification_results is true" do
      it "does not create a new pact version" do
        subject
        expect(PactBroker::Pacts::PactVersion.count).to eq 1
      end
    end

    context "when base_equality_only_on_content_that_affects_verification_results is false" do
      let(:base_equality_only_on_content_that_affects_verification_results) { false }

      it "creates a new version" do
        subject
        expect(PactBroker::Pacts::PactVersion.count).to eq 2
      end
    end
  end
end
