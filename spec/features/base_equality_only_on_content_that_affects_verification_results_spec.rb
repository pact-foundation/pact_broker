RSpec.describe "base_equality_only_on_content_that_affects_verification_results" do
  let(:td) { TestDataBuilder.new }
  let(:json_content_1) { load_fixture('foo-bar.json') }
  let(:json_content_2) do
    pact_hash = load_json_fixture('foo-bar.json')
    pact_hash['interactions'] = pact_hash['interactions'].reverse
    pact_hash.to_json
  end
  let(:base_equality_only_on_content_that_affects_verification_results) { true }

  before do
    PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = base_equality_only_on_content_that_affects_verification_results
    td.create_pact_with_hierarchy("Foo", "1", "Bar", json_content_1)
      .create_verification(provider_version: "5")
      .create_consumer_version("2")
      .create_pact(json_content: json_content_2)
  end

  context "when a pact is published with a different order of interactions to a previous version, but which is otherwise the same" do
    context "when base_equality_only_on_content_that_affects_verification_results is true" do
      it "applies the verifications from the previous version" do
        expect(PactBroker::Matrix::Row.all).to contain_hash(consumer_version_number: "2", provider_version_number: "5")
      end
    end

    context "when base_equality_only_on_content_that_affects_verification_results is false" do
      let(:base_equality_only_on_content_that_affects_verification_results) { false }

      it "does not apply the verifications from the previous version" do
        expect(PactBroker::Matrix::Row.all).to_not contain_hash(consumer_version_number: "2", provider_version_number: "5")
      end
    end
  end
end
