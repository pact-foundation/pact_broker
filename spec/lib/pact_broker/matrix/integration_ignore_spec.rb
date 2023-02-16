require "pact_broker/matrix/service"
require "support/matrix_test_support"

module PactBroker
  module Matrix
    describe Service do
      describe "find" do
        include MatrixQueryContentForApproval
        include PactBroker::MatrixTestSupport

        INTEGRATION_IGNORE_APPROVALS = {}

        subject { Service.can_i_deploy(selectors, options) }

        after do
          print_matrix_results(subject) if ENV["DEBUG"] == "true"
        end

        after do | example |
          INTEGRATION_IGNORE_APPROVALS[example.full_description] = matrix_query_content_for_approval(subject)
        end

        after(:all) do
          Approvals.verify(INTEGRATION_IGNORE_APPROVALS, :name => file_name_to_approval_name(__FILE__) , format: :json)
        end

        let(:options) { {} }

        shared_examples_for "without any ignore selectors" do
          context "without any ignore selectors" do
            let(:ignore_selectors) { [] }

            its(:deployment_status_summary) { is_expected.to_not be_deployable}
          end
        end

        shared_examples_for "with ignore selectors" do
          its(:deployment_status_summary) { is_expected.to be_deployable}
        end

        describe "when deploying a consumer and ignoring a provider" do
          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1") ]
          end

          let(:options) do
            { latest: true, tag: "prod", latestby: "cvp", ignore_selectors: ignore_selectors }
          end

          let(:ignore_selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Bar") ]
          end

          describe "with a missing verification from a provider" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_provider_version("2", tag_names: ["prod"])
            end

            include_context "with ignore selectors"
            include_examples "without any ignore selectors"
          end

          describe "with a failed verification from a provider" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "2", tag_names: ["prod"], success: false)
            end

            include_context "with ignore selectors"
            include_examples "without any ignore selectors"

            context "when ignoring the specific provider version" do
              let(:ignore_selectors) do
                [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2") ]
              end

              include_context "with ignore selectors"
            end

            context "when ignoring a different specific provider version" do
              let(:ignore_selectors) do
                [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "999") ]
              end

              its(:deployment_status_summary) { is_expected.to_not be_deployable}
            end
          end

          describe "when the provider has not been deployed" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "2")
            end

            include_context "with ignore selectors"
            include_examples "without any ignore selectors"
          end

          describe "when the consumer and provider have been specified" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "2", success: false, tag_names: ["prod"])
            end

            let(:selectors) do
              [
                UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
                UnresolvedSelector.new(pacticipant_name: "Bar", tag: "prod", latest: true)
              ]
            end

            include_context "with ignore selectors"
            include_examples "without any ignore selectors"
          end

          describe "when the consumer and provider have been specified and the provider version specified does not exist" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "2", success: true)
            end

            let(:selectors) do
              [
                UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
                UnresolvedSelector.new(pacticipant_name: "Bar", tag: "prod", latest: true)
              ]
            end

            include_context "with ignore selectors"
            include_examples "without any ignore selectors"
          end

          describe "when the provider to ignore does not exist" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "NotBar")
                .create_verification(provider_version: "2", success: true)
            end

            let(:selectors) do
              [
                UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
              ]
            end

            it "includes a warning about the incorrect ignore selector" do
              expect(subject.deployment_status_summary.reasons.collect(&:class)).to include(PactBroker::Matrix::IgnoreSelectorDoesNotExist)
            end
          end

          describe "when the provider version to ignore does not exist" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "2", success: true)
            end

            let(:selectors) do
              [
                UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
              ]
            end

            let(:ignore_selectors) do
              [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "999") ]
            end

            it "includes a warning about the incorrect ignore selector" do
              expect(subject.deployment_status_summary.reasons.collect(&:class)).to include(PactBroker::Matrix::IgnoreSelectorDoesNotExist)
            end
          end
        end

        describe "when deploying a provider and ignoring a consumer" do
          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2") ]
          end

          let(:options) do
            { latest: true, tag: "prod", latestby: "cvp", ignore_selectors: ignore_selectors }
          end

          let(:ignore_selectors) do
            []
          end

          let(:ignore_selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Foo") ]
          end

          describe "with a missing verification from a provider" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_consumer_version_tag("prod")
                .create_provider_version("2")
            end

            let(:ignore_selectors) { [] }

            it "does not allows the provider to be deployed" do
              expect(subject.deployment_status_summary).to_not be_deployable
              expect(subject.deployment_status_summary.reasons.collect(&:class)).to include(PactBroker::Matrix::PactNotEverVerifiedByProvider)
            end
          end

          describe "with a failed verification from a provider" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_consumer_version_tag("prod")
                .create_verification(provider_version: "2", success: false)
            end

            include_context "with ignore selectors"
            include_examples "without any ignore selectors"

            context "when ignoring the specific consumer version" do
              let(:ignore_selectors) do
                [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1") ]
              end

              include_context "with ignore selectors"
            end

            context "when ignoring the wrong specific consumer version" do
              let(:ignore_selectors) do
                [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "wrong") ]
              end

              its(:deployment_status_summary) { is_expected.to_not be_deployable}
            end
          end
        end
      end
    end
  end
end
