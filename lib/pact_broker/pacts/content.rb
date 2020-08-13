require 'pact_broker/pacts/parse'
require 'pact_broker/pacts/sort_content'
require 'pact_broker/pacts/generate_interaction_sha'

module PactBroker
  module Pacts
    class Content
      include GenerateInteractionSha

      def initialize pact_hash
        @pact_hash = pact_hash
      end

      def self.from_json json_content
        new(Parse.call(json_content))
      end

      def self.from_hash pact_hash
        new(pact_hash)
      end

      def to_hash
        pact_hash
      end

      def to_json
        pact_hash.to_json
      end

      def sort
        Content.from_hash(SortContent.call(pact_hash))
      end

      def interactions_missing_test_results
        return [] unless messages_or_interactions
        messages_or_interactions.reject do | interaction |
          interaction['tests']&.any?
        end
      end

      def with_test_results(test_results)
        # new format
        if test_results.is_a?(Array)
          tests = test_results
        else
          # old format
          tests = test_results && test_results['tests']
          if tests.nil? || !tests.is_a?(Array) || tests.empty?
            tests = []
          end
        end

        new_pact_hash = pact_hash.dup
        if interactions && interactions.is_a?(Array)
          new_pact_hash['interactions'] = merge_verification_results(interactions, tests)
        end

        if messages && messages.is_a?(Array)
          new_pact_hash['messages'] = merge_verification_results(messages, tests)
        end
        Content.from_hash(new_pact_hash)
      end

      def with_ids(overwrite_existing_id = true)
        new_pact_hash = pact_hash.dup
        if interactions && interactions.is_a?(Array)
          new_pact_hash['interactions'] = add_ids(interactions, overwrite_existing_id)
        end

        if messages && messages.is_a?(Array)
          new_pact_hash['messages'] = add_ids(messages, overwrite_existing_id)
        end
        Content.from_hash(new_pact_hash)
      end

      def interaction_ids
        messages_or_interaction_or_empty_array.collect do | interaction |
          interaction['_id']
        end.compact
      end

      # Half thinking this belongs in GenerateSha
      def content_that_affects_verification_results
        if interactions || messages
          cont = {}
          cont['interactions'] = interactions if interactions
          cont['messages'] = messages if messages
          cont['pact_specification_version'] = pact_specification_version if pact_specification_version
          cont
        else
          pact_hash
        end
      end

      def messages
        pact_hash.is_a?(Hash) ? pact_hash['messages'] : nil
      end

      def interactions
        pact_hash.is_a?(Hash) ? pact_hash['interactions'] : nil
      end

      def messages_or_interactions
        messages || interactions
      end

      def messages_or_interaction_or_empty_array
        messages_or_interactions || []
      end

      def pact_specification_version
        maybe_pact_specification_version_1 = pact_hash['metadata']['pactSpecification']['version'] rescue nil
        maybe_pact_specification_version_2 = pact_hash['metadata']['pact-specification']['version'] rescue nil
        maybe_pact_specification_version_3 = pact_hash['metadata'] && pact_hash['metadata']['pactSpecificationVersion'] rescue nil
        maybe_pact_specification_version_1 || maybe_pact_specification_version_2 || maybe_pact_specification_version_3
      end

      private

      attr_reader :pact_hash

      def add_ids(interactions, overwrite_existing_id)
        interactions.map do | interaction |
          if interaction.is_a?(Hash)
            if !interaction.key?("_id") || overwrite_existing_id
              # just in case there is a previous ID in there
              interaction_without_id = interaction.reject { |k, _| k == "_id" }
              # make the _id the first key in the hash when rendered to JSON
              { "_id" => generate_interaction_sha(interaction_without_id) }.merge(interaction)
            else
              interaction
            end
          else
            interaction
          end
        end
      end

      def merge_verification_results(interactions, tests)
        interactions.collect(&:dup).collect do | interaction |
          interaction['tests'] = tests.select do | test |
            test_is_for_interaction(interaction, test)
          end
          interaction
        end
      end

      def test_is_for_interaction(interaction, test)
        test.is_a?(Hash) && interaction.is_a?(Hash) && ( interaction_ids_match(interaction, test) || description_and_state_match(interaction, test))
      end

      def interaction_ids_match(interaction, test)
        interaction['_id'] && interaction['_id'] == test['interactionId']
      end

      def description_and_state_match(interaction, test)
        test['interactionDescription'] && test['interactionDescription'] == interaction['description'] && test['interactionProviderState'] == interaction['providerState']
      end
    end
  end
end
