require 'spec_helper'
require 'pact_broker/api/renderers/html_pact_renderer'

module PactBroker
  module Api
    module Renderer
      describe HtmlPactRenderer do

        let(:json_content) { load_fixture('renderer_pact.json') }

        subject { HtmlPactRenderer.call json_content }

        describe ".call" do
          it "renders the pact as HTML" do
            expect(subject).to include("<html>")
            expect(subject).to include("</html>")
            expect(subject).to include('<link rel="stylesheet"')
            expect(subject).to include('href="/stylesheets/github.css"')
            expect(subject).to include('<pre><code')
            expect(subject).to include('&quot;method&quot;:')
            expect(subject).to match /<h\d>.*Some Consumer/
            expect(subject).to match /<h\d>.*Some Provider/
          end
        end

      end
    end
  end
end