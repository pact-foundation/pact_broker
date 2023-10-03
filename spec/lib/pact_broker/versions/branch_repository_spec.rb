require "pact_broker/versions/branch_repository"

module PactBroker
  module Versions
    describe BranchRepository do
      describe "find_all_branches_for_pacticipant" do
        before do
          td.create_consumer("Other")
            .create_consumer_version("1", branch: "blah")
            .create_consumer("Foo")
            .create_consumer_version("1", branch: "main")
            .add_day
            .create_consumer_version("2", branch: "main")
            .add_day
            .create_consumer_version("3", branch: "feat/foo")
            .add_day
            .create_consumer_version("4", branch: "feat/bar")
            .add_day
        end

        let(:filter_options) { {} }
        let(:pagination_options) { {} }
        let(:eager_load_associations) { [] }
        let(:pacticipant) { td.and_return(:pacticipant) }

        subject { BranchRepository.new.find_all_branches_for_pacticipant(pacticipant, filter_options, pagination_options, eager_load_associations) }

        it "does not eager load the associations" do
          expect(subject.first.associations[:pacticipant]).to be_nil
        end

        context "with no options" do
          it "returns all the branches for the pacticipant starting with the most recent" do
            expect(subject.size).to eq 3
            expect(subject.first.name).to eq "feat/bar"
            expect(subject.last.name).to eq "main"
          end
        end

        context "with pagination options" do
          let(:pagination_options) { { page_size: 1, page_number: 2 } }

          it "uses the pagination options" do
            expect(subject).to contain_exactly(have_attributes(name: "feat/foo"))
          end
        end

        context "with filter options" do
          let(:filter_options) { { query_string: "feat" } }

          it "returns the matching branches" do
            expect(subject).to contain_exactly(have_attributes(name: "feat/foo"), have_attributes(name: "feat/bar"))
          end
        end

        context "with eager_load_associations" do
          let(:eager_load_associations) { [:pacticipant] }

          it "eager loads the associations" do
            expect(subject.first.associations[:pacticipant]).to_not be_nil
          end
        end
      end

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
