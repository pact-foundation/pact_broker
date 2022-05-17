require "pact_broker/matrix/resolved_selector"

module PactBroker
  module Matrix
    describe ResolvedSelector do
      describe "#version_does_not_exist_description" do
        let(:subject) do
          PactBroker::Matrix::ResolvedSelector.for_pacticipant_and_non_existing_version(pacticipant, original_selector, :specified, false)
        end

        let(:original_selector) do
          {
            pacticipant_name: pacticipant_name,
            tag: tag,
            branch: branch,
            environment_name: environment_name,
            pacticipant_version_number: pacticipant_version_number,
          }
        end

        let(:pacticipant) { double("pacticipant", name: pacticipant_name, id: 1)}

        let(:pacticipant_name) { "Foo" }
        let(:tag) { nil }
        let(:branch) { nil }
        let(:environment_name) { nil }
        let(:pacticipant_version_number) { nil }

        its(:version_does_not_exist_description) { is_expected.to eq "No pacts or verifications have been published for Foo" }

        context "when it was specified by tag" do
          let(:tag) { "dev" }

          its(:version_does_not_exist_description) { is_expected.to eq "No version with tag dev exists for Foo" }
        end

        context "when it was specified by branch" do
          let(:branch) { "main" }

          its(:version_does_not_exist_description) { is_expected.to eq "No version of Foo from branch main exists" }
        end

        context "when it was specified by environment" do
          let(:environment_name) { "test" }

          its(:version_does_not_exist_description) { is_expected.to eq "No version of Foo is currently recorded as deployed or released in environment test" }
        end

        context "when it was specified by verison number" do
          let(:pacticipant_version_number) { "1" }

          its(:version_does_not_exist_description) { is_expected.to eq "No pacts or verifications have been published for version 1 of Foo" }
        end
      end
    end
  end
end
