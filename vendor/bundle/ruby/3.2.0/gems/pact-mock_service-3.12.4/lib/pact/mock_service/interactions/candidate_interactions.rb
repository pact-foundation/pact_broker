module Pact
  module MockService
    module Interactions
      class CandidateInteractions < Array

        def matching_interactions actual_request
          select do | candidate_interaction |
            candidate_interaction.request.matches? actual_request
          end
        end

      end
    end
  end
end
