require 'pact_broker/api/decorators/integration_decorator'
require 'pact_broker/integrations/integration'

module PactBroker
  module Api
    module Decorators
      describe IntegrationDecorator do
        let(:integration) do
          instance_double(PactBroker::Integrations::Integration,
            consumer: consumer,
            provider: provider
          )
        end
        let(:consumer) { double("consumer", name: "the consumer") }
        let(:provider) { double("provider", name: "the provider") }

        let(:expected_hash) do
          {
            "consumer" => {
              "name" => "the consumer"
            },
            "provider" => {
              "name" => "the provider"
            }
          }
        end

        let(:json) { IntegrationDecorator.new(integration).to_json }
        subject { JSON.parse(json) }

        it "generates a hash" do
          expect(subject).to match_pact expected_hash
        end
      end
    end
  end
end
