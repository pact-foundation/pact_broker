require 'pact/consumer_contract'
require 'pact/reification'
require 'redcarpet'

module PactBroker
  module Api
    module Renderers
      class HtmlPactRenderer

        def self.call json_content
          new(json_content).call
        end

        def initialize json_content
          @json_content = json_content
        end

        def call
          "<html><head>#{head}</head><body>#{html}</body></html>"
        end

        private

        def head
          '<link rel="stylesheet" type="text/css" href="/stylesheets/github.css">'
        end

        def markdown
          renderer.call consumer_contract
        end

        def html
          Redcarpet::Markdown.new(Redcarpet::Render::HTML, :fenced_code_blocks => true, :lax_spacing => true).render(markdown)
        end

        def consumer_contract
          Pact::ConsumerContract.from_json(@json_content)
        end

        def renderer
          # InteractionsRenderer got renamed to ConsumerContractRenderer
          if defined? Pact::Doc::Markdown::InteractionsRenderer
            Pact::Doc::Markdown::InteractionsRenderer
          else
            Pact::Doc::Markdown::ConsumerContractRenderer
          end

        end

      end
    end
  end
end