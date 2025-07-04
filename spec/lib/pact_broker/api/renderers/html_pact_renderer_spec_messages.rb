require "pact_broker/api/renderers/html_pact_renderer"

module PactBroker
  module Api
    module Renderers
      describe HtmlPactRenderer do
        def render_and_compare(fixture_name)
          json_content = File.read("spec/fixtures/#{fixture_name}.json")
          expected_markdown = File.read("spec/fixtures/#{fixture_name}.md").strip
          pact = instance_double(PactBroker::Domain::Pact, json_content: json_content)

          renderer = HtmlPactRenderer.new(pact)

          result = renderer.send(:markdown)

          expect(result.strip).to eq(expected_markdown.strip)
        end

        it "renders correct markdown for a pact with mixed v4 sync/async interactions" do
          render_and_compare("v4_mixed_http_sync_async_interactions")
        end

        it "renders correct markdown for a pact with v3 async messages" do
          render_and_compare("v3_async_messages")
        end

        it "renders correct markdown for a pact with v4 sync messages" do
          render_and_compare("v4_sync_messages")
        end        
      end
    end
  end
end
