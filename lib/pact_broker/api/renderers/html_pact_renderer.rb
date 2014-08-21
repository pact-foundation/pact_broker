require 'pact/consumer_contract'
require 'pact/reification'
require 'redcarpet'
require 'pact/doc/markdown/consumer_contract_renderer'

module PactBroker
  module Api
    module Renderers
      class HtmlPactRenderer

        def self.call pact
          new(pact).call
        end

        def initialize pact
          @json_content = pact.json_content
        end

        def call
          "<html><head>#{head}</head><body>#{html}</body></html>"
        end

        private

        def head
          '<link rel="stylesheet" type="text/css" href="/stylesheets/github.css">'
        end

        def markdown
          Pact::Doc::Markdown::ConsumerContractRenderer.call consumer_contract
        end

        def html
          Redcarpet::Markdown.new(Redcarpet::Render::HTML, :fenced_code_blocks => true, :lax_spacing => true).render(markdown)
        end

        def consumer_contract
          Pact::ConsumerContract.from_json(@json_content)
        end

      end
    end
  end
end