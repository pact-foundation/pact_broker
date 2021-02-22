require 'pact_broker/matrix/can_i_deploy_query_schema'

module PactBroker
  module Api
    module Contracts
      describe CanIDeployQuerySchema do
        subject { CanIDeployQuerySchema.call(params) }

        context "with valid params" do
          let(:params) do
            {
              pacticipant: "foo",
              version: "1",
              to: "prod"
            }
          end

          it { is_expected.to be_empty }
        end

        context "with a to tag and an environment specified" do
          let(:params) do
            {
              pacticipant: "foo",
              version: "1",
              environment: "prod",
              to: "prod"
            }
          end
          it { is_expected.to_not be_empty }
        end
      end
    end
  end
end
