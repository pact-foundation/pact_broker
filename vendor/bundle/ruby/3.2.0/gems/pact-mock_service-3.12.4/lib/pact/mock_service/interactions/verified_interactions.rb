module Pact
  module MockService
    module Interactions
      class VerifiedInteractions < Array

        def << interaction
          unless find_matching_description_and_provider_state interaction
            super
          end
        end

        def find_matching_description_and_provider_state interaction
          find do |candidate_interaction|
            candidate_interaction.matches_criteria?(description: interaction.description, provider_state: interaction.provider_state)
          end
        end
      end
    end
  end
end
