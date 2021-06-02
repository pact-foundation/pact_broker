require "pact_broker/matrix/can_i_deploy_query_schema"

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
          before do
            allow(PactBroker::Deployments::EnvironmentService).to receive(:find_by_name).and_return(double("environment"))
          end

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

        context "when the environment does exist" do
          before do
            allow(PactBroker::Deployments::EnvironmentService).to receive(:find_by_name).and_return(double("environment"))
          end

          let(:params) do
            {
              pacticipant: "foo",
              version: "1",
              environment: "prod"
            }
          end

          it { is_expected.to be_empty }
        end

        context "when the environment does not exist" do
          before do
            allow(PactBroker::Deployments::EnvironmentService).to receive(:find_by_name).and_return(nil)
          end

          let(:params) do
            {
              pacticipant: "foo",
              version: "1",
              environment: "prod"
            }
          end

          its([:environment, 0]) { is_expected.to eq "environment with name 'prod' does not exist" }
        end
      end
    end
  end
end
