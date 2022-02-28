require "pact_broker/api/resources/can_i_deploy_pacticipant_version_by_branch_to_environment_badge"

module PactBroker
  module Api
    module Resources
      describe CanIDeployPacticipantVersionByBranchToEnvironmentBadge do
        before do
          allow_any_instance_of(described_class).to receive(:branch_service).and_return(branch_service)
          allow_any_instance_of(described_class).to receive(:badge_service).and_return(badge_service)

          allow(branch_service).to receive(:find_branch).and_return(branch)
          allow(badge_service). to receive(:can_i_deploy_badge_url).and_return("http://badge_url")
          allow(badge_service). to receive(:error_badge_url).and_return("http://error_badge_url")

          allow_any_instance_of(CanIDeployPacticipantVersionByBranchToEnvironmentBadge).to receive(:pacticipant).and_return(pacticipant)
          allow_any_instance_of(CanIDeployPacticipantVersionByBranchToEnvironmentBadge).to receive(:version).and_return(version)
          allow_any_instance_of(CanIDeployPacticipantVersionByBranchToEnvironmentBadge).to receive(:environment).and_return(environment)
          allow_any_instance_of(CanIDeployPacticipantVersionByBranchToEnvironmentBadge).to receive(:results).and_return(results)
        end

        let(:branch_service) { class_double("PactBroker::Versions::BranchService").as_stubbed_const }
        let(:badge_service) { class_double("PactBroker::Badges::Service").as_stubbed_const }

        let(:pacticipant) { double("pacticipant") }
        let(:version) { double("version") }
        let(:environment) { double("environment") }
        let(:branch) { double("branch") }
        let(:results) { instance_double("PactBroker::Matrix::QueryResultsWithDeploymentStatusSummary", deployable?: true )}

        let(:path) { "/pacticipants/Foo/branches/main/latest-version/can-i-deploy/to-environment/dev/badge" }

        subject { get(path, { label: "custom-label" }) }

        context "when everything is found" do
          it "return the badge URL" do
            expect(badge_service). to receive(:can_i_deploy_badge_url).with("main", "dev", "custom-label", true)
            expect(subject.headers["Location"]).to eq "http://badge_url"
          end
        end

        context "when the pacticipant is not found" do
          let(:pacticipant) { nil }

          it "returns an error badge URL" do
            expect(badge_service).to receive(:error_badge_url).with("pacticipant", "not found")
            expect(subject.headers["Location"]).to eq "http://error_badge_url"
          end
        end

        context "when the version is not found and the branch is not found" do
          let(:version) { nil }
          let(:branch) { nil }

          it "returns an error badge URL" do
            expect(badge_service).to receive(:error_badge_url).with("branch", "not found")
            expect(subject.headers["Location"]).to eq "http://error_badge_url"
          end
        end

        context "when the version is not found and the branch is found" do
          let(:version) { nil }

          it "returns an error badge URL" do
            expect(badge_service).to receive(:error_badge_url).with("version", "not found")
            expect(subject.headers["Location"]).to eq "http://error_badge_url"
          end
        end

        context "when the environment is not found" do
          let(:environment) { nil }

          it "returns an error badge URL" do
            expect(badge_service).to receive(:error_badge_url).with("environment", "not found")
            expect(subject.headers["Location"]).to eq "http://error_badge_url"
          end
        end
      end
    end
  end
end
