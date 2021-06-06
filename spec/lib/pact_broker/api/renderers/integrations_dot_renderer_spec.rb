require "pact_broker/api/renderers/integrations_dot_renderer"

module PactBroker
  module Api
    module Renderers
      describe IntegrationsDotRenderer do

        # TODO work out how to handle apostrophes etc

        let(:integrations) do
          [
            double("integration", consumer_name: "Foo", provider_name: "Bar"),
            double("integration", consumer_name: "Wiffle", provider_name: "Foo Thing")
          ]
        end

        let(:expected_content) { load_fixture("expected.gv") }

        describe "#call" do
          subject { IntegrationsDotRenderer.call(integrations) }

          it "renders a dot file" do
            expect(subject).to eq expected_content
          end
        end
      end
    end
  end
end
