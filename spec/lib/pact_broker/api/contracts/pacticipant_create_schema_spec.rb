require "pact_broker/api/contracts/pacticipant_schema"

module PactBroker
  module Api
    module Contracts
      describe PacticipantCreateSchema do
        let(:params) do
          {
            name: "pact-broker",
            displayName: "Pact Broker",
            mainBranch: main_branch,
            repositoryUrl: "https://github.com/pact-foundation/pact_broker",
            repositoryName: "pact_broker",
            repositoryNamespace: "pact-foundation"
          }
        end

        let(:main_branch) { "main" }

        subject { PacticipantCreateSchema.call(params) }

        context "with valid params" do
          it { is_expected.to be_empty }
        end

        context "with empty params" do
          let(:params) do
            {
              repositoryUrl: "",
              repositoryName: "",
              repositoryNamespace: ""
            }
          end

          its([:name, 0]) { is_expected.to include "name is missing" }
        end
      end
    end
  end
end
