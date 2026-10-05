require "cgi"
require "json"
require "pact_broker/api/renderers/markdown"

module PactBroker
  module Api
    module Renderers
      module Markdown
        # Presents one interaction from a parsed pact hash for the markdown
        # templates. Bodies are printed as stored, so v1 pacts show their
        # inline json_class matcher objects verbatim.
        class InteractionViewModel
          MARKDOWN_BOLD_CHARACTERS = "**"
          ORDERED_KEYS = ["method", "path", "query", "status", "headers", "body"].freeze
          ASYNC_REQUEST = "ASYNC_REQUEST"

          def initialize interaction, pact
            @interaction = interaction
            @pact = pact
          end

          def id
            @id ||= begin
              full_desc = if has_provider_state?
                            "#{description} given #{provider_state_name}"
                          else
                            description
                          end
              CGI.escapeHTML(full_desc.gsub(/\s+/, "_"))
            end
          end

          def sortable_id
            "#{(interaction["description"] || "").downcase} #{http_response["status"]} #{(provider_state_name || "").downcase}"
          end

          def consumer_name
            markdown_escape pact.dig("consumer", "name")
          end

          def provider_name
            markdown_escape pact.dig("provider", "name")
          end

          def has_provider_state?
            !provider_state_name.nil? && !provider_state_name.empty?
          end

          def provider_state start_of_sentence = false
            markdown_escape apply_capitals(provider_state_name.strip, start_of_sentence)
          end

          def formatted_provider_states mark_bold: false
            bold_marker = mark_bold ? MARKDOWN_BOLD_CHARACTERS : ""

            provider_state_names.map do |name|
              "#{bold_marker}#{markdown_escape(apply_capitals(name.strip, false))}#{bold_marker}"
            end.join(" and ")
          end

          def description start_of_sentence = false
            return "" unless interaction["description"]
            markdown_escape apply_capitals(interaction["description"].strip, start_of_sentence)
          end

          def request
            return ASYNC_REQUEST if async?
            JSON.pretty_generate(clean_request)
          end

          def response
            JSON.pretty_generate(clean_response)
          end

          def async?
            interaction["type"] == "Asynchronous/Messages" || !interaction.key?("request")
          end

          private

          attr_reader :interaction, :pact

          def sync?
            interaction["type"] == "Synchronous/Messages"
          end

          def http_request
            interaction["request"].is_a?(Hash) ? interaction["request"] : {}
          end

          def http_response
            interaction["response"].is_a?(Hash) ? interaction["response"] : {}
          end

          def clean_request
            if sync?
              http_request.slice("contents", "metadata")
            else
              ordered_clean_hash(http_request).tap do |h|
                h["body"] = http_request["body"] if http_request["body"]
              end
            end
          end

          def clean_response
            if sync?
              Array(interaction["response"]).map { |item| item.to_h.slice("contents", "metadata") }
            elsif async?
              { "contents" => interaction["contents"], "metadata" => interaction["metadata"] }
            else
              ordered_clean_hash(http_response)
            end
          end

          # Removes empty header and body hashes, as an empty hash means
          # "allow anything" and reads more cleanly when omitted.
          def ordered_clean_hash source
            ORDERED_KEYS.each_with_object({}) do |key, target|
              if source.key? key
                target[key] = source[key] unless value_is_an_empty_hash(source[key])
              end
            end
          end

          def value_is_an_empty_hash value
            value.is_a?(Hash) && value.empty?
          end

          def provider_state_names
            states = interaction["providerStates"]
            if states.is_a?(Array) && states.any?
              states.map { |state| state.is_a?(Hash) ? state["name"] : state }.compact
            else
              [interaction["providerState"] || interaction["provider_state"]].compact
            end
          end

          def provider_state_name
            provider_state_names.first
          end

          def apply_capitals string, start_of_sentence = false
            start_of_sentence ? capitalize_first_letter(string) : lowercase_first_letter(string)
          end

          def capitalize_first_letter string
            string[0].upcase + string[1..-1]
          end

          def lowercase_first_letter string
            string[0].downcase + string[1..-1]
          end

          def markdown_escape string
            return nil unless string
            string.gsub(MARKDOWN_SPECIAL_CHARS_REGEXP) { |char| "\\#{char}" }
          end
        end
      end
    end
  end
end
