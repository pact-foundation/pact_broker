require 'pact_broker/api/contracts/environment_contract'

module PactBroker
  module Api
    module Contracts
      describe EnvironmentContract do

        before do
          allow(PactBroker.configuration).to receive(:environments).and_return(environments)
        end

        let(:environments) { ["uat", "prod"] }
        let(:params) { {environment_name: 'prod' } }
        let(:environment) { instance_double('PactBroker::Environments::Environment', name: nil) }
        let(:contract) { EnvironmentContract.new(environment) }

        subject { contract.validate(params) }

        context "with a name that matches the specified environments" do
          it { is_expected.to be true }
        end

        context "when the environment contains a regular expression" do
          let(:environments) { ["prod.*"] }

          context "when the environment_name matches" do
            let(:params) { {environment_name: 'production' } }
            it { is_expected.to be true }
          end

          context "when the environment_name does not matches" do
            let(:params) { {environment_name: 'theprod' } }
            it { is_expected.to be false }
          end
        end

        context "with a name that does not match the specified environments" do
          let(:params) { { environment_name: 'test' } }

          it { is_expected.to be false }

          it "sets an error message" do
            subject
            expect(contract.errors[:name].first).to eq "is not a valid environment name"
          end
        end
      end
    end
  end
end
