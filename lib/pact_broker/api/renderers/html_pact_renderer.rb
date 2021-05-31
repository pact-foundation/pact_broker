require 'pact/consumer_contract'
require 'pact/reification'
require 'redcarpet'
require 'pact/doc/markdown/consumer_contract_renderer'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/logging'
require 'rack'

module PactBroker
  module Api
    module Renderers
      class HtmlPactRenderer

        class NotAPactError < StandardError; end

        include PactBroker::Logging

        def self.call pact, options = {}
          new(pact, options).call
        end

        def initialize pact, options = {}
          @json_content = pact.json_content
          @pact = pact
          @options = options
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
         "<title>#{title}</title>
          <link rel='stylesheet' type='text/css' href='#{base_url}/stylesheets/github.css'>
          <link rel='stylesheet' type='text/css' href='#{base_url}/stylesheets/pact.css'>
          <link rel='stylesheet' type='text/css' href='#{base_url}/stylesheets/github-json.css'>
          <link rel='stylesheet' type='text/css' href='#{base_url}/css/bootstrap.min.css'>
          <link rel='stylesheet' type='text/css' href='#{base_url}/stylesheets/material-menu.css'>
          <link rel='stylesheet' type='text/css' href='#{base_url}/stylesheets/jquery-confirm.min.css'>
          <script src='#{base_url}/javascripts/highlight.pack.js'></script>
          <script src='#{base_url}/javascripts/jquery-3.5.1.min.js'></script>
          <script src='#{base_url}/js/bootstrap.min.js'></script>
          <script src='#{base_url}/javascripts/material-menu.js'></script>
          <script src='#{base_url}/javascripts/pact.js'></script>
          <script src='#{base_url}/javascripts/jquery-confirm.min.js'></script>
          <script>hljs.initHighlightingOnLoad();</script>"
        end

        def pact_metadata
          "<div class='pact-metadata'>
            <ul>
              #{badge_list_item}
              #{badge_markdown_item}
              <li>
                <span class='name'>#{consumer_name} version:</span>
                <span class='value'>#{consumer_version_number}#{tags}</span>
              </li>
              <li>
                <span class='name' title='#{published_date}'>Date published:</span>
                <span class='value' title='#{published_date}'>#{published_date_in_words}</span>
              </li>
              <li>
                <a href=\"#{json_url}\">View in API Browser</a>
              </li>
              <li>
                <a href=\"#{matrix_url}\">View Matrix</a>
              </li>
              <li>
                <a href=\"#{base_url}/\">Home</a>
              </li>
              <li>
                <span data-consumer-name=\"#{consumer_name}\"
                      data-provider-name=\"#{provider_name}\"
                      data-consumer-version-number=\"#{consumer_version_number}\"
                      data-pact-url=\"#{pact_url}\"
                      class='more-options kebab-horizontal'
                      aria-hidden='true'></span>
              </li>
            </ul>
          </div>"
        end

        def badge_list_item
            "<li class='pact-badge'>
              <img src=\"#{badge_url}\"/>
            </li>
            "
        end

        def badge_markdown_item
          "<li class='pact-badge-markdown' style='display:none'>
              <textarea rows='3' cols='100'>#{badge_markdown}</textarea>
          </li>"
        end

        def badge_markdown
          warning = if badges_protected?
                      "If the broker is protected by authentication, set `enable_public_badge_access` to true in the configuration to enable badges to be embedded in a markdown file.\n"
                    else
                      ""
                    end
          "#{warning}[![#{@pact.consumer.name}/#{@pact.provider.name} Pact Status](#{badge_url})](#{badge_target_url})"
        end

        def badges_protected?
          !PactBroker.configuration.enable_public_badge_access
        end

        def base_url
          @options[:base_url] || ''
        end

        def title
          "Pact between #{consumer_name} and #{provider_name}"
        end

        def consumer_version_number
          h(@pact.consumer_version_number)
        end

        def consumer_name
          h(@pact.consumer.name)
        end

        def provider_name
          h(@pact.provider.name)
        end

        def published_date
          @pact.created_at.to_time.localtime.to_datetime.strftime("%a %d %b %Y, %l:%M%P %:z")
        end

        def published_date_in_words
          PactBroker::DateHelper.distance_of_time_in_words(@pact.created_at.to_time, DateTime.now) + " ago"
        end

        def json_url
          PactBroker::Api::PactBrokerUrls.hal_browser_url pact_url, base_url
        end

        def pact_url
          PactBroker::Api::PactBrokerUrls.pact_url base_url, @pact
        end

        def matrix_url
          PactBroker::Api::PactBrokerUrls.matrix_for_pact_url(@pact, base_url)
        end

        def latest_pact_url
          PactBroker::Api::PactBrokerUrls.latest_pact_url base_url, @pact
        end

        def badge_target_url
          base_url
        end

        def badge_url
          @options[:badge_url]
        end

        def tags
          if @pact.consumer_version_tag_names.any?
            tag_names = @pact.consumer_version_tag_names.collect{ |t| h(t) }.join(", ")
            " (#{tag_names})"
          else
            ""
          end
        end

        def markdown
          Pact::Doc::Markdown::ConsumerContractRenderer.call consumer_contract
        rescue StandardError
          heading = "### A contract between #{@pact.consumer.name} and #{@pact.provider.name}"
          warning = "_Note: this contract could not be parsed to a v1 or v2 Pact, showing raw content instead._"
          pretty_json = JSON.pretty_generate(@pact.content_hash)
          "#{heading}\n#{warning}\n```json\n#{pretty_json}\n```\n"
        end

        def html
          Redcarpet::Markdown.new(Redcarpet::Render::HTML, :fenced_code_blocks => true, :lax_spacing => true).render(markdown)
        end

        def consumer_contract
          Pact::ConsumerContract.from_json(@json_content)
        rescue => e
          logger.info "Could not parse the following content to a Pact due to #{e.class} #{e.message}, showing raw content instead: #{@json_content}"
          raise NotAPactError
        end

        def h string
          Rack::Utils.escape_html(string)
        end
      end
    end
  end
end
