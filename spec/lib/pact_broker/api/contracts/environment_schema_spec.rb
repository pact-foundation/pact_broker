require 'pact_broker/api/contracts/environment_schema'

module PactBroker
  module Api
    module Contracts
      describe EnvironmentSchema do
        before do
          allow(PactBroker::Deployments::EnvironmentService).to receive(:find_by_name).and_return(existing_environment)
        end
        let(:existing_environment) { nil }
        let(:name) { "test" }

        let(:params) do
          {
            uuid: "1234",
            name: name,
            displayName: "Test",
            production: false,
            contacts: contacts
          }
        end

        let(:contacts) do
          [{
            name: "Foo",
            details: { email: "foo@bar.com" }
          }]
        end

        subject { EnvironmentSchema.call(params) }

        context "with valid params" do
          it { is_expected.to be_empty }
        end

        context "with a name with a new line" do
          let(:name) { "test 1" }

          it { is_expected.to_not be_empty }
        end

        context "with empty params" do
          let(:params) { {} }

          it { is_expected.to_not be_empty }
        end

        context "when there is another environment with the same name but a different uuid" do
          let(:existing_environment) { instance_double("PactBroker::Deployments::Environment", uuid: "5678")}

          its([:name]) { is_expected.to eq ["Another environment with name 'test' already exists."] }
        end

        context "when there is another environment with the same name and same uuid" do
          let(:existing_environment) { instance_double("PactBroker::Deployments::Environment", uuid: "1234")}

          it { is_expected.to be_empty }
        end

        context "with no owner name" do
          let(:contacts) do
            [{
              details: { email: "foo@bar.com" }
            }]
          end

          its([:contacts, 0]) { is_expected.to eq "name is missing at index 0" }
        end

        context "with string contact details" do
          let(:contacts) do
            [{
              name: "foo",
              details: "foo"
            }]
          end

          its([:contacts, 0]) { is_expected.to eq "details must be a hash at index 0" }
        end
      end
    end
  end
end
