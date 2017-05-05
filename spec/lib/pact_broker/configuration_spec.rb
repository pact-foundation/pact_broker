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

      describe "protect_with_basic_auth" do
        let(:config) do
          config = Configuration.new
          config.protect_with_basic_auth [:foo, :bar], {some: 'credentials'}
          config.protect_with_basic_auth :foo, {some: 'othercredentials'}
          config
        end

        it "groups credentials by scope" do
          expect(config.basic_auth_credentials_list_for(:foo)).to eq([{some: 'credentials'},{some: 'othercredentials'}])
          expect(config.basic_auth_credentials_list_for(:bar)).to eq([{some: 'credentials'}])
        end

        describe "protect_with_basic_auth?" do
          it "indicates whether a scope is protected" do
            expect(config.protect_with_basic_auth?(:foo)).to be true
            expect(config.protect_with_basic_auth?(:bar)).to be true
            expect(config.protect_with_basic_auth?(:wiffle)).to be false
          end
        end
      end
    end
  end
end
