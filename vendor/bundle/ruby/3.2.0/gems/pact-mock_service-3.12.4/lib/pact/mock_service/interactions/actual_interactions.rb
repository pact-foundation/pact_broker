require 'pact/mock_service/interactions/candidate_interactions'

module Pact
  module MockService
    module Interactions
      class ActualInteractions

        attr_reader :matched_interactions, :interaction_mismatches, :unexpected_requests

        def initialize
          clear
        end

        # For testing, sigh
        def clear
          @matched_interactions = []
          @interaction_mismatches = []
          @unexpected_requests = []
        end

        def register_matched interaction
          @matched_interactions << interaction
        end

        def register_unexpected_request request
          @unexpected_requests << request
        end

        def register_interaction_mismatch interaction_mismatch
          @interaction_mismatches << interaction_mismatch
        end

      end
    end
  end
end
