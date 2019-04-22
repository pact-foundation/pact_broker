require 'json'

module PactBroker
  module Pacts
    module Merger

      extend self

      def conflict? original_json, additional_json
        original, additional = [original_json, additional_json].map{|str| JSON.parse(str, PACT_PARSING_OPTIONS) }

        additional["interactions"].any? do |new_interaction|
          original["interactions"].any? do |original_interaction|
            same_description_and_state?(original_interaction, new_interaction) &&
              !same_request_properties?(original_interaction["request"], new_interaction["request"])
          end
        end
      end

      # Accepts two hashes representing pacts, outputs a merged hash
      # Does not make any guarantees about order of interactions
      # TODO: should not modify original!
      # TODO: is not checking response for equality!
      # TODO: should have separate tests!
      def merge_pacts original_json, additional_json
        original, additional = [original_json, additional_json].map{|str| JSON.parse(str, PACT_PARSING_OPTIONS) }

        new_pact = original

        additional["interactions"].each do |new_interaction|
          # check to see if this interaction matches an existing interaction
          overwrite_index = original["interactions"].find_index do |original_interaction|
            same_description_and_state?(original_interaction, new_interaction)
          end

          # overwrite existing interaction if a match is found, otherwise appends the new interaction
          if overwrite_index
            new_pact["interactions"][overwrite_index] = new_interaction
          else
            new_pact["interactions"] << new_interaction
          end
        end

        new_pact.to_json
      end

      private

      def same_description_and_state? original, additional
        original["description"] == additional["description"] &&
          normalized_provider_states(original) == normalized_provider_states(additional)
      end

      def normalized_provider_states(interaction)
        interaction.values_at("provider_state", "providerState", "providerStates").compact.first
      end

      def same_request_properties? original, additional
        attributes_match = %w(method path query body headers).all? do |attribute|
          original[attribute] == additional[attribute]
        end
      end
    end
  end
end
