require 'pact_broker/deployments/deployed_version'

module PactBroker
  module Deployments
    describe DeployedVersion do
      let!(:environment) { td.create_environment("test").and_return(:environment) }
      let!(:version) do
        td.create_consumer
          .create_consumer_version("1")
          .and_return(:consumer_version)
      end

      let(:params) do
        {
          uuid: "1234",
          version_id: version.id,
          pacticipant_id: version.pacticipant_id,
          environment_id: environment.id,
          target: target
        }
      end

      let(:target) { nil }

      subject { DeployedVersion.create(params) }

      it "creates a CurrentlyDeployedVersionId" do
        expect{ subject }.to change { CurrentlyDeployedVersionId.count}.by(1)
      end

      it "sets the currently deployed version id" do
        expect(subject.currently_deployed_version_id.deployed_version_id).to eq subject.id
      end

      context "when a deployed version for the same environment and nil instance name exists" do
        before do
          td.create_deployed_version_for_consumer_version(environment_name: "test", target: target)
        end

        it "does not make a new currently deployed version id" do
          expect{ subject }.to change { CurrentlyDeployedVersionId.count}.by(0)
        end

        it "updates the currently deployed version id" do
          expect { subject }.to change { CurrentlyDeployedVersionId.last.deployed_version_id }
          expect(CurrentlyDeployedVersionId.last.deployed_version_id).to eq subject.id
        end

        its(:currently_deployed) { is_expected.to be true }
      end

      context "when a deployed version for the same environment and same instance name exists" do
        before do
          td.create_deployed_version_for_consumer_version(environment_name: "test", target: target)
        end

        let(:target) { "green" }

        its(:currently_deployed) { is_expected.to be true }

        it "does not make a new currently deployed version id" do
          expect{ subject }.to change { CurrentlyDeployedVersionId.count}.by(0)
        end

        it "updates the currently deployed version id" do
          expect { subject }.to change { CurrentlyDeployedVersionId.last.deployed_version_id }
          expect(CurrentlyDeployedVersionId.last.deployed_version_id).to eq subject.id
        end

        describe "the previously deployed version" do
          it "is no longer currently deployed" do
            subject
            version.refresh
            expect(version.deployed_versions.first.currently_deployed).to be false
          end
        end
      end

      context "when a deployed version for the same environment and different instance name exists" do
        before do
          td.create_deployed_version_for_consumer_version(environment_name: "test", target: "blue")
        end

        let(:target) { "green" }

        it "makes a new currently deployed version id" do
          expect{ subject }.to change { CurrentlyDeployedVersionId.count}.by(1)
          expect(CurrentlyDeployedVersionId.last.deployed_version_id).to eq subject.id
        end

        describe "the previously deployed version" do
          it "is still currently deployed" do
            subject
            version.refresh
            expect(version.deployed_versions.first.currently_deployed).to be true
          end
        end

        its(:currently_deployed) { is_expected.to be true }
      end
    end
  end
end
