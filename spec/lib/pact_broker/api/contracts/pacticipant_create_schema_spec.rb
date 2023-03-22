require "pact_broker/api/contracts/pacticipant_create_schema"

module PactBroker
  module Api
    module Contracts
      describe PacticipantCreateSchema do
        let(:params) do
          {
            name: name,
            displayName: "Pact Broker",
            mainBranch: main_branch,
            repositoryUrl: "https://github.com/pact-foundation/pact_broker",
            repositoryName: "pact_broker",
            repositoryNamespace: "pact-foundation"
          }
        end

        let(:name) { "pact-broker" }

        let(:main_branch) { "main" }

        subject { PacticipantCreateSchema.call(params) }

        context "with valid params" do
          it { is_expected.to be_empty }
        end

        context "with an empty name" do
          let(:name) { "" }

          it { is_expected.to_not be_empty }
        end

        context "with a blank name" do
          let(:name) { " " }

          it { is_expected.to_not be_empty }
        end

        context "with a branch that has a space" do
          let(:main_branch) { "origin main" }

          its([:mainBranch, 0]) { is_expected.to eq "cannot contain spaces" }
        end

        context "with empty params" do
          let(:params) do
            {
              repositoryUrl: "",
              repositoryName: "",
              repositoryNamespace: ""
            }
          end

          its([:name, 0]) { is_expected.to include "is missing" }
        end
      end
    end
  end
end
