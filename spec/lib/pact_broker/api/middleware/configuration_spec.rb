require "pact_broker/api/middleware/configuration"

module PactBroker
  module Api
    module Middleware
      class TestApp
        def call(_)
          [200, {}, [PactBroker.configuration.allow_dangerous_contract_modification.to_s]]
        end
      end

      describe Configuration do
        describe "#call" do
          let(:configuration) do
            conf = PactBroker::Configuration.default_configuration
            conf.allow_dangerous_contract_modification = false
            conf
          end
          let(:app) { Configuration.new(TestApp.new, configuration) }
          let(:rack_env) { {} }

          subject { get("/", nil, rack_env) }

          context "with no overrides" do
            it "uses the default configuration" do
              expect(subject.body).to eq "false"
            end
          end

          context "with overrides" do
            let(:rack_env) do
              { "pactbroker.configuration_overrides" => { allow_dangerous_contract_modification: true }}
            end

            it "overrides the configuration for the duration of the request" do
              expect(subject.body).to eq "true"
            end
          end
        end
      end
    end
  end
end
