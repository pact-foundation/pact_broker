require 'spec_helper'
require 'pact_broker/configuration'
require 'pact_broker/api/renderers/html_pact_renderer'

module PactBroker
  describe Configuration do

    context "default configuration" do
      describe ".html_pact_renderer" do

        let(:json_content) { {a: 'b'}.to_json }

        it "calls the inbuilt HtmlPactRenderer" do
          expect(PactBroker::Api::Renderers::HtmlPactRenderer).to receive(:call).with(json_content)
          PactBroker.configuration.html_pact_renderer.call json_content
        end

      end
    end
  end
end