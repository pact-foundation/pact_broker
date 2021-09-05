require "pact_broker/versions/branch_version_repository"

module PactBroker
  module Versions
    describe BranchVersionRepository do
      describe "add_branch" do
        before do
          allow(repository).to receive(:pacticipant_service).and_return(pacticipant_service)
          allow(pacticipant_service).to receive(:maybe_set_main_branch)
        end
        let!(:version) { td.create_consumer("Foo").create_consumer_version("1", branch: "original-branch").and_return(:consumer_version) }
        let(:new_branch_name) { "new-branch" }
        let(:pacticipant_service) { class_double("PactBroker::Pacticipants::Service").as_stubbed_const }
        let(:repository) { BranchVersionRepository.new }

        subject { repository.add_branch(version, new_branch_name).version.refresh }

        it "calls the pacticipant_service.maybe_set_main_branch" do
          expect(pacticipant_service).to receive(:maybe_set_main_branch).with(instance_of(PactBroker::Domain::Pacticipant), new_branch_name)
          subject
        end

        context "when the branch does not already exist" do
          it "creates a branch" do
            expect { subject }.to change { PactBroker::Versions::Branch.count }.by(1)
          end

          it "creates a branch_version" do
            expect { subject }.to change { PactBroker::Versions::BranchVersion.count }.by(1)
          end

          it "adds the branch_version to the version" do
            expect(subject.branch_versions.count).to eq 2
            expect(subject.branch_versions.last.branch_name).to eq "new-branch"
          end

          it "updates the branch head" do
            branch_head = subject.pacticipant.branch_head_for("new-branch")
            expect(branch_head.version.id).to eq subject.refresh.id
          end
        end

        context "when the branch and branch version do already exist" do
          let(:new_branch_name) { "original-branch" }

          it "does not creates a branch" do
            expect { subject }.to_not change { PactBroker::Versions::Branch.order(:name).collect(&:name) }
          end

          it "does not create a branch_version" do
            expect { subject }.to change { PactBroker::Versions::BranchVersion.count }.by(0)
          end

          it "keeps the branch_version on the version" do
            expect(subject.branch_versions.count).to eq 1
            expect(subject.branch_versions.first.branch_name).to eq "original-branch"
          end

          it "does not change the branch head" do
            branch_head = subject.pacticipant.branch_head_for("original-branch")
            expect(branch_head.version).to eq subject
          end
        end
      end
    end
  end
end
