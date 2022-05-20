require "pact_broker/matrix/resolved_selector"

module PactBroker
  module Matrix
    describe ResolvedSelector do
      describe "#version_does_not_exist_description" do
        context "for an existing version" do
          let(:subject) do
            PactBroker::Matrix::ResolvedSelector.for_pacticipant_and_version(pacticipant, version, original_selector, :specified, false, one_of_many)
          end

          let(:original_selector) do
            {
              pacticipant_name: pacticipant_name,
              tag: tag,
              branch: branch,
              environment_name: environment_name,
              pacticipant_version_number: pacticipant_version_number,
              main_branch: main_branch,
              latest: latest
            }
          end

          let(:pacticipant) { double("pacticipant", name: pacticipant_name, id: 1)}
          let(:version) { double("version", number: "123", id: 2, values: version_values)}

          let(:pacticipant_name) { "Foo" }
          let(:tag) { nil }
          let(:branch) { nil }
          let(:environment_name) { nil }
          let(:main_branch) { nil }
          let(:pacticipant_version_number) { nil }
          let(:latest) { nil }
          let(:one_of_many) { false }
          let(:version_values) { {} }

          its(:description) { is_expected.to eq "version 123 of Foo" }

          context "when it was specified by tag" do
            let(:tag) { "dev" }

            its(:description) { is_expected.to eq "a version of Foo with tag dev (123)" }
          end

          context "when it was specified by tag and latest" do
            let(:tag) { "dev" }
            let(:latest) { true }

            its(:description) { is_expected.to eq "the latest version of Foo with tag dev (123)" }
          end

          context "when it was specified by branch" do
            let(:branch) { "main" }

            its(:description) { is_expected.to eq "the version of Foo from branch main (123)" }

            context "when one of many" do
              let(:one_of_many) { true }

              its(:description) { is_expected.to eq "one of the versions of Foo from branch main (123)" }
            end
          end

          context "when it was specified by branch latest" do
            let(:branch) { "main" }
            let(:latest) { true }

            its(:description) { is_expected.to eq "the latest version of Foo from branch main (123)" }
          end

          context "when it was specified by environment" do
            let(:environment_name) { "test" }

            its(:description) { is_expected.to eq "the version of Foo currently deployed or released to test (123)" }
          end

          context "when it was specified by version number" do
            let(:pacticipant_version_number) { "123" }

            its(:description) { is_expected.to eq "version 123 of Foo" }
          end

          context "when specified by main_branch" do
            let(:main_branch) { true }
            # the branch_name will be present in the values of the version returned by this selector
            let(:version_values) { { branch_name: "develop" } }

            its(:description) { is_expected.to eq "the version of Foo from branch develop (123)" }

            context "when one of many" do
              let(:one_of_many) { true }

              its(:description) { is_expected.to eq "one of the versions of Foo from branch develop (123)" }
            end
          end

          context "when specified by main_branch and latest" do
            let(:main_branch) { true }
            let(:latest) { true }
            let(:version_values) { { branch_name: "develop" } }

            its(:description) { is_expected.to eq "the latest version of Foo from branch develop (123)" }
          end
        end

        context "for non existing version" do
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
              main_branch: main_branch,
              latest: latest
            }
          end

          let(:pacticipant) { double("pacticipant", name: pacticipant_name, id: 1)}

          let(:pacticipant_name) { "Foo" }
          let(:tag) { nil }
          let(:branch) { nil }
          let(:environment_name) { nil }
          let(:main_branch) { nil }
          let(:pacticipant_version_number) { nil }
          let(:latest) { nil }

          its(:version_does_not_exist_description) { is_expected.to eq "No pacts or verifications have been published for Foo" }

          context "when it was specified by tag" do
            let(:tag) { "dev" }

            its(:description) { is_expected.to eq "a version of Foo with tag dev (no such version exists)" }
            its(:version_does_not_exist_description) { is_expected.to eq "No version with tag dev exists for Foo" }
          end

          context "when it was specified by tag and latest" do
            let(:tag) { "dev" }
            let(:latest) { true }

            its(:description) { is_expected.to eq "the latest version of Foo with tag dev (no such version exists)" }
            its(:version_does_not_exist_description) { is_expected.to eq "No version with tag dev exists for Foo" }
          end

          context "when it was specified by branch" do
            let(:branch) { "main" }

            its(:description) { is_expected.to eq "a version of Foo from branch main (no such version exists)" }
            its(:version_does_not_exist_description) { is_expected.to eq "No version of Foo from branch main exists" }
          end

          context "when it was specified by branch latest" do
            let(:branch) { "main" }
            let(:latest) { true }

            its(:description) { is_expected.to eq "the latest version of Foo from branch main (no such version exists)" }
            its(:version_does_not_exist_description) { is_expected.to eq "No version of Foo from branch main exists" }
          end

          context "when it was specified by environment" do
            let(:environment_name) { "test" }

            its(:description) { is_expected.to eq "a version of Foo currently deployed or released to test (no version is currently recorded as deployed/released in this environment)" }
            its(:version_does_not_exist_description) { is_expected.to eq "No version of Foo is currently recorded as deployed or released in environment test" }
          end

          context "when it was specified by version number" do
            let(:pacticipant_version_number) { "1" }

            its(:description) { is_expected.to eq "version 1 of Foo (no such version exists)" }
            its(:version_does_not_exist_description) { is_expected.to eq "No pacts or verifications have been published for version 1 of Foo" }
          end

          context "when specified by main_branch" do
            let(:main_branch) { true }

            its(:description) { is_expected.to eq "a version of Foo from the main branch (no such version exists)" }
            its(:version_does_not_exist_description) { is_expected.to eq "No version of Foo from the main branch exists" }
          end

          context "when specified by main_branch and latest" do
            let(:main_branch) { true }
            let(:latest) { true }

            its(:description) { is_expected.to eq "a version of Foo from the main branch (no such version exists)" }
            its(:version_does_not_exist_description) { is_expected.to eq "No version of Foo from the main branch exists" }
          end
        end
      end
    end
  end
end
