require "pact_broker/versions/branch_service"

module PactBroker
  module Versions
    describe BranchService do
      describe ".find_branch_version" do
        before do
          td.create_consumer("Foo")
            .create_consumer_version("1", branch: "main")
            .create_consumer_version("1", branch: "feat/x")
            .create_consumer_version("2", branch: "main")
        end

        subject { BranchService.find_branch_version(pacticipant_name: "Foo", version_number: "1", branch_name: "main") }

        its(:version_number) { is_expected.to eq "1" }
      end

      describe "#create_branch_version" do
        subject { BranchService.find_or_create_branch_version(pacticipant_name: "Foo", version_number: "1", branch_name: "main") }

        context "when nothing exists" do
          it "creates and returns the branch version" do
            expect(subject.pacticipant.name).to eq "Foo"
            expect(subject.version_number).to eq "1"
            expect(subject.branch_name).to eq "main"
          end
        end

        context "when everything exists except the branch version" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("0", branch: "main")
          end

          it "does not create the branch" do
            expect{ subject }.to_not change { PactBroker::Versions::Branch.where(name: "main").count }
          end

          it "creates and returns the branch version" do
            expect(subject.pacticipant.name).to eq "Foo"
            expect(subject.version_number).to eq "1"
            expect(subject.branch_name).to eq "main"
            expect(subject.branch_head).to_not be nil
          end
        end

        context "when everything exists" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", branch: "main")

            BranchVersion.dataset.update(updated_at: Sequel.datetime_class.now - 10, created_at: Sequel.datetime_class.now - 10)
          end

          it "does not create a new branch version" do
            expect{ subject }.to_not change { PactBroker::Versions::BranchVersion.count }
          end

          it "updates the updated_at" do
            expect{ subject }.to change { PactBroker::Versions::BranchVersion.first.updated_at }
          end

          it "does not change the created_at" do
            expect{ subject }.to_not change { PactBroker::Versions::BranchVersion.first.created_at }
          end
        end
      end
    end
  end
end
