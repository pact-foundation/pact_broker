require 'json'

module PactBroker
  module Pacts
    module MergeVerificationResults
      def self.call(interactions, test_results)
        return interactions unless test_results.is_a?(Array)
        interactions.collect do | interaction |
          interaction.merge(find_test_results_for_interaction(interaction["_id"], test_results))
        end
      end

      def self.find_test_results_for_interaction(interaction_id, test_results)
        test_results
          .select{ | test_result | test_result["interactionId"] == interaction_id }
          .collect{ | test_result | test_result.reject{ | key, _ | key == "interactionId"} }
          .first || {}
      end

      def merge_verification_results(interactions, test_results)
        MergeVerificationResults.call(interactions, test_results)
      end
    end
  end
end
