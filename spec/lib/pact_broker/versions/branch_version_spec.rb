require "pact_broker/versions/branch_version"

module PactBroker
  module Versions
    describe BranchVersion do
      describe "#latest?" do
        before do
          td.create_consumer("Foo")
            .create_consumer_version("2", branch: "foo")
            .create_consumer_version("3", branch: "foo")
        end

        context "when it is the latest version for the branch" do
          subject { td.find_version("Foo", "3").branch_versions.first }

          its(:latest?) { is_expected.to be true }
        end

        context "when it is not the latest version for the branch" do
          subject { td.find_version("Foo", "2").branch_versions.first }

          its(:latest?) { is_expected.to be false }
        end
      end

      describe "number_of_versions_from_head" do
        before do
          td.create_consumer("Foo")
            .create_consumer_version("2", branch: "foo")
            .create_consumer_version("3", branch: "foo")
            .create_consumer_version("4", branch: "bar")
        end

        subject { PactBroker::Versions::BranchVersion.first }

        its(:number_of_versions_from_head) { is_expected.to eq 1 }
      end

      describe "main_branch?" do
        before do
          td.create_consumer("Foo", main_branch: "devel")
            .create_consumer_version("1", branch: "devel")
            .create_consumer_version("2", branch: "feat/foo")
        end

        context "when the branch name matches the pacticipant's main branch" do
          let(:subject) { td.find_version("Foo", "1").branch_versions.first }

          its(:main_branch?) { is_expected.to be true }
        end

        context "when the branch name does not match pacticipant's main branch" do
          let(:subject) { td.find_version("Foo", "2").branch_versions.first }

          its(:main_branch?) { is_expected.to be false }
        end
      end
    end
  end
end
