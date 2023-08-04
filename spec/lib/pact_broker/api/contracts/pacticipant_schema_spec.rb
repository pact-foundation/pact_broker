require "pact_broker/api/contracts/pacticipant_schema"

module PactBroker
  module Api
    module Contracts
      describe PacticipantSchema do
        include PactBroker::Test::ApiContractSupport

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

        subject { format_errors_the_old_way(PacticipantSchema.call(params)) }

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

          it { is_expected.to be_empty }
        end

        context "with branch names that contain spaces" do
          let(:main_branch) { "main foo" }

          its([:mainBranch, 0]) { is_expected.to include "cannot contain spaces" }
        end
      end
    end
  end
end
