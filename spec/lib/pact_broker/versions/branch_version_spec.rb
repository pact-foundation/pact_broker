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
    end
  end
end
