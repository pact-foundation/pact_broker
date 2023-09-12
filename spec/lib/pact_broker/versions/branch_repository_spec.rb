require "pact_broker/versions/branch_repository"

module PactBroker
  module Versions
    describe BranchRepository do
      describe "delete_branch" do
        before do
          td.create_consumer("foo")
            .create_consumer_version("1", branch: "main")
            .create_consumer_version("2", branch: "main")
            .create_consumer_version("3", branch: "not-main")
            .create_consumer("bar")
            .create_consumer_version("1", branch: "main")
        end

        let(:branch) { BranchRepository.new.find_branch(pacticipant_name: "foo", branch_name: "main") }

        subject { BranchRepository.new.delete_branch(branch) }

        it "deletes the branch" do
          expect{ subject }.to change { Branch.count }.by(-1)
        end

        it "deletes the branch versions" do
          expect{ subject }.to change { BranchVersion.count }.by(-2)
        end

        it "deletes the branch head" do
          expect{ subject }.to change { BranchHead.count }.by(-1)
        end

        it "does not delete the versions" do
          expect{ subject }.to_not change { PactBroker::Domain::Version.count }
        end
      end
    end
  end
end
