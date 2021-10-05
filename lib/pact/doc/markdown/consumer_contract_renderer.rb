require "pact/doc/markdown/interaction_renderer"
require "pact/doc/sort_interactions"
require "rack/utils"

module Pact
  module Doc
    module Markdown
      class ConsumerContractRenderer

        def initialize consumer_contract
          @consumer_contract = consumer_contract
        end

        def self.call consumer_contract
          new(consumer_contract).call
        end

        def call
          title + summaries_title + summaries + interactions_title + full_interactions
        end

        private

        attr_reader :consumer_contract

        def title
          "# A pact between #{consumer_name} and #{provider_name}\n\n"
        end

        def interaction_renderers
          @interaction_renderers ||= sorted_interactions.collect{|interaction| InteractionRenderer.new interaction, @consumer_contract}
        end

        def summaries_title
          "### Requests from #{consumer_name} to #{provider_name}\n\n"
        end

        def interactions_title
          "### Interactions\n\n"
        end

        def summaries
          interaction_renderers.collect(&:render_summary).join
        end

        def full_interactions
          interaction_renderers.collect(&:render_full_interaction).join
        end

        def sorted_interactions
          SortInteractions.call(consumer_contract.interactions)
        end

        def consumer_name
          h(markdown_escape consumer_contract.consumer.name)
        end

        def provider_name
          h(markdown_escape consumer_contract.provider.name)
        end

        def markdown_escape string
          string.gsub("*","\\*").gsub("_","\\_")
        end

        def h(text)
          Rack::Utils.escape_html(text)
        end
      end
    end
  end
end
