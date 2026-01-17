require 'pact/mock_service/interactions/candidate_interactions'

module Pact
  module MockService
    module Interactions
      class ExpectedInteractions < Array

        def find_candidate_interactions actual_request
          Pact::MockService::Interactions::CandidateInteractions.new(
            select do | interaction |
              interaction.request.matches_route? actual_request
            end
          )
        end
      end
    end
  end
end
