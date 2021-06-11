require "pact_broker/api/decorators/integrations_decorator"

module PactBroker
  module Api
    module Decorators
      describe IntegrationsDecorator do
        before do
          allow(IntegrationDecorator).to receive(:new).and_return(integration_decorator)
        end
        let(:integration_decorator) { instance_double(IntegrationDecorator).as_null_object }
        let(:integration) { double("integration") }
        let(:integrations_decorator) { IntegrationsDecorator.new([integration]) }
        let(:options) { { user_options: { resource_url: "http://example.org/integrations" } } }

        let(:json) { integrations_decorator.to_json(options) }

        subject { JSON.parse(json) }

        it "includes a list of integrations" do
          expect(subject["_embedded"]["integrations"]).to be_an(Array)
        end

        it "includes a link to itself" do
          expect(subject["_links"]["self"]["href"]).to eq "http://example.org/integrations"
        end
      end
    end
  end
end
