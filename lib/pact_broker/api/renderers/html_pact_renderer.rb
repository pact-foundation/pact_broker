require 'pact/consumer_contract'
require 'pact/reification'
require 'redcarpet'
require 'pact/doc/markdown/consumer_contract_renderer'
require 'pact_broker/api/pact_broker_urls'

module PactBroker
  module Api
    module Renderers
      class HtmlPactRenderer

        def self.call pact
          new(pact).call
        end

        def initialize pact
          @json_content = pact.json_content
          @pact = pact
        end

        def call
          "<html>
            <head>#{head}</head>
            <body>
              #{pact_metadata}#{html}
            </body>
          </html>"
        end

        private

        def head
         "<link rel='stylesheet' type='text/css' href='/stylesheets/github.css'>
          <link rel='stylesheet' type='text/css' href='/stylesheets/pact.css'>
          <link rel='stylesheet' type='text/css' href='/stylesheets/github-json.css'>
          <script src='/javascripts/highlight.pack.js'></script>
          <script>hljs.initHighlightingOnLoad();</script>"
        end

        def pact_metadata
          "<div class='pact-metadata'>
            <ul>
              <li>
                <span class='name'>#{@pact.consumer.name} version:</span>
                <span class='value'>#{@pact.consumer_version_number}</span>
              </li>
              <li>
                <span class='name'>Date published:</span>
                <span class='value'>#{published_date}</span>
              </li>
              <li>
                <a href=\"#{json_url}\">View in HAL Browser</a>
              </li>
            </ul>
          </div>"
        end

        def published_date
          @pact.updated_at.to_time.localtime.to_datetime.strftime("%d/%m/%Y %l:%M%p %:z")
        end

        def json_url
          PactBroker::Api::PactBrokerUrls.hal_browser_url pact_url
        end

        def pact_url
          PactBroker::Api::PactBrokerUrls.pact_url '', @pact
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