module Pact
  module MockService
    module Interactions
      class Verification

        def initialize expected_interactions, actual_interactions
          @expected_interactions = expected_interactions
          @actual_interactions = actual_interactions
        end

        def all_matched?
          interaction_diffs.empty?
        end

        def interaction_diffs
          {
            :missing_interactions => missing_interactions_summaries,
            :interaction_mismatches => interaction_mismatches_summaries,
            :unexpected_requests => unexpected_requests_summaries
          }.each_with_object({}) do | (key, value), hash |
            hash[key] = value if value.any?
          end
        end

        def missing_interactions_summaries
          missing_interactions.collect(&:request).collect(&:method_and_path)
        end

        def interaction_mismatches_summaries
          actual_interactions.interaction_mismatches.collect(&:short_summary)
        end

        def unexpected_requests_summaries
          actual_interactions.unexpected_requests.collect(&:method_and_path)
        end

        def missing_interactions
          expected_interactions - actual_interactions.matched_interactions - @actual_interactions.interaction_mismatches.collect(&:candidate_interactions).flatten
        end

        def interaction_mismatches
          actual_interactions.interaction_mismatches
        end

        private

        attr_reader :expected_interactions, :actual_interactions

      end
    end
  end
end
