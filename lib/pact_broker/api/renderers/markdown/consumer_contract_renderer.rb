require "pact_broker/api/renderers/markdown/interaction_renderer"
require "pact_broker/api/renderers/markdown/interaction_view_model"
require "rack/utils"
require "pact_broker/api/renderers/markdown"

module PactBroker
  module Api
    module Renderers
      module Markdown
        class ConsumerContractRenderer

          # Raised when the content does not have the shape of a pact.
          class NotAPactError < StandardError; end

          def initialize pact_hash
            unless pact_hash.is_a?(Hash) && pact_hash["consumer"].is_a?(Hash) && pact_hash["provider"].is_a?(Hash)
              raise NotAPactError, "content does not have consumer and provider objects"
            end
            @pact_hash = pact_hash
          end

          def self.call pact_hash
            new(pact_hash).call
          end

          def call
            title + summaries_title + summaries + interactions_title + full_interactions
          end

          private

          attr_reader :pact_hash

          def title
            "# A pact between #{consumer_name} and #{provider_name}\n\n"
          end

          def interaction_renderers
            @interaction_renderers ||= sorted_interactions.collect { |view_model| InteractionRenderer.new(view_model) }
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
            interactions.collect { |interaction| InteractionViewModel.new(interaction, pact_hash) }.sort_by(&:sortable_id)
          end

          # v3 message pacts keep their interactions under "messages"
          def interactions
            Array(pact_hash["interactions"] || pact_hash["messages"])
          end

          def consumer_name
            h(markdown_escape pact_hash.dig("consumer", "name"))
          end

          def provider_name
            h(markdown_escape pact_hash.dig("provider", "name"))
          end

          def markdown_escape string
            return nil unless string
            string.gsub(MARKDOWN_SPECIAL_CHARS_REGEXP) { |char| "\\#{char}" }
          end

          def h(text)
            Rack::Utils.escape_html(text)
          end
        end
      end
    end
  end
end
