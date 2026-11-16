require "json"
require "pact_broker/janus"

module PactBroker
  module Pacts
    module Merger

      extend self

      def conflict? original_json, additional_json
        original, additional = [original_json, additional_json].map{|str| JSON.parse(str, **PACT_PARSING_OPTIONS) }

        if janus?(original) || janus?(additional)
          janus_conflict?(original, additional)
        elsif original["interactions"].nil? || additional["interactions"].nil?
          true
        else
          additional["interactions"].any? do |new_interaction|
            original["interactions"].any? do |original_interaction|
              same_description_and_state?(original_interaction, new_interaction) &&
                !same_request_properties?(original_interaction["request"], new_interaction["request"])
            end
          end
        end
      end

      # Accepts two hashes representing pacts, outputs a merged hash
      # Does not make any guarantees about order of interactions
      # TODO: should not modify original!
      # TODO: is not checking response for equality!
      # TODO: should have separate tests!
      def merge_pacts original_json, additional_json
        original, additional = [original_json, additional_json].map{|str| JSON.parse(str, **PACT_PARSING_OPTIONS) }

        if janus?(original) || janus?(additional)
          return merge_janus_contracts(original, additional, additional_json)
        end

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

      def janus?(content)
        PactBroker::Janus.contract?(content)
      end

      # Two Janus contracts conflict when they record an interaction of the same identity
      # differently (ADR 0065 of Pact Janus). A Janus contract and a pact always conflict.
      def janus_conflict?(original, additional)
        return true unless mergeable_janus?(original) && mergeable_janus?(additional)
        additional["interactions"].any? do |new_interaction|
          original["interactions"].any? do |original_interaction|
            same_janus_identity?(original_interaction, new_interaction) &&
              without_id(original_interaction) != without_id(new_interaction)
          end
        end
      end

      # Merges as a pact is merged, an interaction replacing the one of the same identity. Content
      # that is not a Janus contract on both sides cannot be merged, and replaces what was there.
      def merge_janus_contracts(original, additional, additional_json)
        return additional_json unless mergeable_janus?(original) && mergeable_janus?(additional)
        new_contract = original
        additional["interactions"].each do |new_interaction|
          overwrite_index = original["interactions"].find_index do |original_interaction|
            same_janus_identity?(original_interaction, new_interaction)
          end
          if overwrite_index
            new_contract["interactions"][overwrite_index] = new_interaction
          else
            new_contract["interactions"] << new_interaction
          end
        end
        new_contract.to_json
      end

      def mergeable_janus?(content)
        janus?(content) && content["interactions"].is_a?(Array)
      end

      def same_janus_identity?(original, additional)
        PactBroker::Janus.interaction_identity(original) == PactBroker::Janus.interaction_identity(additional)
      end

      # The broker adds an _id to each interaction it stores
      def without_id(interaction)
        interaction.reject { |key, _| key == "_id" }
      end

      def same_description_and_state? original, additional
        original["description"] == additional["description"] &&
          normalized_provider_states(original) == normalized_provider_states(additional)
      end

      def normalized_provider_states(interaction)
        interaction.values_at("provider_state", "providerState", "providerStates").compact.first
      end

      def same_request_properties? original, additional
        %w(method path query body headers).all? do |attribute|
          original[attribute] == additional[attribute]
        end
      end
    end
  end
end
