require "pact_broker/matrix/service"
require "support/matrix_test_support"

module PactBroker
  module Matrix
    describe Service do
      describe "find with environments" do
        include MatrixQueryContentForApproval
        include PactBroker::MatrixTestSupport

        ENVIRONMENT_APPROVALS = {}

        subject { Service.can_i_deploy(selectors, options) }

        after do
          print_matrix_results(subject) if ENV["DEBUG"] == "true"
        end

        after do | example |
          ENVIRONMENT_APPROVALS[example.full_description] = matrix_query_content_for_approval(subject)
        end

        after(:all) do
          Approvals.verify(ENVIRONMENT_APPROVALS, :name => file_name_to_approval_name(__FILE__) , format: :json)
        end

        context "when there is a successful verification between the provider in test environment and the consumer to be deployed" do
          before do
            td.create_environment("test")
              .create_pact_with_verification("Foo", "1", "Bar", "2")
              .create_deployed_version_for_provider_version
              .create_verification(provider_version: "3", number: 2, success: false)
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
            ]
          end

          let(:options) { { latestby: "cvpv", environment_name: "test" } }

          it "allows the consumer to be deployed" do
            expect(subject.deployment_status_summary).to be_deployable
          end
        end

        context "when there is an unsuccessful verification between the provider in test environment and the consumer to be deployed" do
          before do
            td.create_environment("test")
              .create_pact_with_verification("Foo", "1", "Bar", "2", false)
              .create_deployed_version_for_provider_version
              .create_verification(provider_version: "3", number: 3, success: true)
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
            ]
          end

          let(:options) { { latestby: "cvpv", environment_name: "test" } }

          it "does not allow the consumer to be deployed" do
            expect(subject.deployment_status_summary).to_not be_deployable
          end
        end

        context "when the provider has not been deployed to the given environment" do
          before do
            td.create_environment("test")
              .create_pact_with_verification("Foo", "1", "Bar", "2")
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
            ]
          end

          let(:options) { { latestby: "cvpv", environment_name: "test" } }

          it "does not allow the consumer to be deployed" do
            expect(subject.deployment_status_summary).to_not be_deployable
          end
        end

        context "when the consumer has not been deployed to the given environment" do
          before do
            td.create_environment("test")
              .create_pact_with_verification("Foo", "1", "Bar", "2")
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2"),
            ]
          end

          let(:options) { { latestby: "cvpv", environment_name: "test" } }

          it "allows the provider to be deployed" do
            expect(subject.deployment_status_summary).to be_deployable
          end
        end

        describe "when deploying a version of a provider with multiple versions of a consumer in production" do
          before do
            td.create_environment("prod")
              .create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_deployed_version_for_consumer_version(environment_name: "prod", target: "1")
              .create_verification(provider_version: "10")
              .create_consumer_version("2")
              .create_pact
              .create_deployed_version_for_consumer_version(environment_name: "prod", target: "2")
          end

          let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "10") ]}
          let(:options) { { environment_name: "prod" } }

          it "knows that there are multiple versions of the consumer in production" do
            subject
            expect(subject.resolved_selectors.select { |s| s.pacticipant_name == "Bar" }.collect(&:one_of_many?)).to eq [false]
            expect(subject.resolved_selectors.select { |s| s.pacticipant_name == "Foo" }.collect(&:one_of_many?)).to eq [true, true]
          end

          context "when a verification for the latest prod version is missing" do
            it "does not allow the provider to be deployed" do
              expect(subject.deployment_status_summary).to_not be_deployable
            end
          end

          context "when there is a successful verification for every prod version of the consumer" do
            before do
              td.create_verification(provider_version: "10")
            end

            it "does allow the provider to be deployed" do
              expect(subject.deployment_status_summary).to be_deployable
            end
          end
        end

        describe "when deploying a version of a consumer with multiple versions of a provider in production" do
          before do
            td.create_environment("prod")
              .create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "10")
              .create_deployed_version_for_provider_version(environment_name: "prod", target: "1")
              .create_consumer_version("2")
              .create_pact
              .create_provider_version("11")
              .create_deployed_version_for_provider_version(environment_name: "prod", target: "2")
          end

          let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "2") ]}
          let(:options) { { environment_name: "prod" } }

          it "knows that there are multiple versions of the provider in production" do
            subject
            expect(subject.resolved_selectors.select { |s| s.pacticipant_name == "Foo" }.collect(&:one_of_many?)).to eq [false]
            expect(subject.resolved_selectors.select { |s| s.pacticipant_name == "Bar" }.collect(&:one_of_many?)).to eq [true, true]
          end

          context "when a verification for the latest prod version is missing" do
            it "does not allow the consumer to be deployed" do
              expect(subject.deployment_status_summary).to_not be_deployable
            end
          end

          context "when there is a successful verification for every prod version of the consumer" do
            before do
              td.create_verification(provider_version: "11")
            end

            it "does allow the consumer to be deployed" do
              expect(subject.deployment_status_summary).to be_deployable
            end
          end
        end

        # --- RELEASES: multiple released provider versions co-resident in an environment (issue #903) ---
        # Exercises the production "cvpv" path, which the pre-existing multi-version blocks above do not
        # (they omit latestby, so apply_latestby never collapses and the bug was never reproduced).
        describe "when deploying a consumer with multiple versions of a provider released to production (latestby cvpv)" do
          let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1") ] }
          let(:options) { { latestby: "cvpv", environment_name: "prod" } }

          context "when an older released provider version has a failing verification" do
            before do
              td.create_environment("prod")
                .create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "10", number: 1, success: false)
                .create_released_version_for_provider_version(environment_name: "prod")
                .create_verification(provider_version: "11", number: 2, success: true)
                .create_released_version_for_provider_version(environment_name: "prod")
            end

            it "does not allow the consumer to be deployed" do
              expect(subject.deployment_status_summary).to_not be_deployable
            end
          end

          context "when every released provider version has a successful verification" do
            before do
              td.create_environment("prod")
                .create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "10", number: 1, success: true)
                .create_released_version_for_provider_version(environment_name: "prod")
                .create_verification(provider_version: "11", number: 2, success: true)
                .create_released_version_for_provider_version(environment_name: "prod")
            end

            it "allows the consumer to be deployed" do
              expect(subject.deployment_status_summary).to be_deployable
            end
          end
        end

        # --- DEPLOYMENTS WITH TARGETS: multiple deployed provider versions on different targets (issue #903) ---
        describe "when deploying a consumer with multiple versions of a provider deployed to production on different targets (latestby cvpv)" do
          let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1") ] }
          let(:options) { { latestby: "cvpv", environment_name: "prod" } }

          context "when an older targeted deployment has a failing verification" do
            before do
              td.create_environment("prod")
                .create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "10", number: 1, success: false)
                .create_deployed_version_for_provider_version(environment_name: "prod", target: "instance-1")
                .create_verification(provider_version: "11", number: 2, success: true)
                .create_deployed_version_for_provider_version(environment_name: "prod", target: "instance-2")
            end

            it "does not allow the consumer to be deployed" do
              expect(subject.deployment_status_summary).to_not be_deployable
            end
          end

          context "when every targeted deployment has a successful verification" do
            before do
              td.create_environment("prod")
                .create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "10", number: 1, success: true)
                .create_deployed_version_for_provider_version(environment_name: "prod", target: "instance-1")
                .create_verification(provider_version: "11", number: 2, success: true)
                .create_deployed_version_for_provider_version(environment_name: "prod", target: "instance-2")
            end

            it "allows the consumer to be deployed" do
              expect(subject.deployment_status_summary).to be_deployable
            end
          end
        end

        # --- DEPLOYMENT WITHOUT TARGET: a redeployment replaces the previous version, so only one is ever live ---
        # Guards that the cvpv change does not alter the standard single-instance record-deployment workflow:
        # deploying Bar 11 (no target) replaces the earlier Bar 10 (no target), so only Bar 11 is currently
        # deployed and considered. Bar 10's failing verification is irrelevant because it is no longer live.
        # If redeployment ever stopped replacing the previous version, cvpv would surface Bar 10's failure and
        # this test would fail.
        describe "when a version is deployed without a target and then replaced by a redeployment (latestby cvpv)" do
          before do
            td.create_environment("prod")
              .create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "10", number: 1, success: false)
              .create_deployed_version_for_provider_version(environment_name: "prod")
              .create_verification(provider_version: "11", number: 2, success: true)
              .create_deployed_version_for_provider_version(environment_name: "prod")
          end

          let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1") ] }
          let(:options) { { latestby: "cvpv", environment_name: "prod" } }

          it "only considers the currently deployed version and allows the consumer to be deployed" do
            expect(subject.deployment_status_summary).to be_deployable
          end
        end
      end
    end
  end
end
