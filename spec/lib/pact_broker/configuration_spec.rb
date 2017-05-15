require 'spec_helper'
require 'pact_broker/configuration'
require 'pact_broker/api/renderers/html_pact_renderer'

module PactBroker
  describe Configuration do

    context "default configuration" do
      describe ".html_pact_renderer" do

        let(:pact) { double('pact') }

        it "calls the inbuilt HtmlPactRenderer" do
          expect(PactBroker::Api::Renderers::HtmlPactRenderer).to receive(:call).with(pact)
          PactBroker.configuration.html_pact_renderer.call pact
        end

      end

      describe "SETTING_NAMES" do
        let(:configuration) { PactBroker::Configuration.new}

        Configuration::SAVABLE_SETTING_NAMES.each do | setting_name |
          describe setting_name do
            it "exists as a method on a PactBroker::Configuration instance" do
              expect(configuration).to respond_to(setting_name)
            end
          end
        end

      end
    end
  end
end
