require 'pact_broker/pacts/parse'
require 'pact_broker/pacts/sort_content'
require 'pact_broker/pacts/generate_interaction_sha'
require 'pact_broker/pacts/merge_verification_results'

module PactBroker
  module Pacts
    class Content
      include GenerateInteractionSha
      include MergeVerificationResults

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

      def with_test_results(test_results)
        new_pact_hash = pact_hash.dup
        if interactions && interactions.is_a?(Array)
          new_pact_hash['interactions'] = merge_verification_results(interactions, test_results)
        end

        if messages && messages.is_a?(Array)
          new_pact_hash['messages'] = merge_verification_results(messages, test_results)
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
    end
  end
end
