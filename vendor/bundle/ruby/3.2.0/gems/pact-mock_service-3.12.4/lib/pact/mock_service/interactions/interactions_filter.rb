require 'pact/mock_service/errors'
require 'pact/mock_service/interactions/interaction_diff_message'

#
# When running in pactfile_write_mode :overwrite, all interactions are cleared from the
# pact file, and all new interactions should be distinct (unique description and provider state).
# When running in pactfile_write_mode :update, an interaction with the same description
# and provider state as an existing one will just overwrite that one interaction.
# When running in pactfile_write_mode :merge, an interaction with the same description and provider
# state must be identical to the existing one, otherwise an exception will be raised.

module Pact
  module MockService
    module Interactions

      def self.filter existing_interactions, pactfile_write_mode
        if pactfile_write_mode == :update
          UpdatableInteractionsFilter.new(existing_interactions)
        elsif pactfile_write_mode == :merge
          MergingInteractionsFilter.new(existing_interactions)
        else
          existing_interactions
        end
      end

      #TODO: think of a better word than filter
      class InteractionsFilter
        def initialize interactions = []
           @interactions = interactions
        end

        def index_of interaction
           @interactions.find_index{ |i| i.matches_criteria?(description: interaction.description, provider_state: interaction.provider_state)}
        end
      end

      class UpdatableInteractionsFilter < InteractionsFilter
        def << interaction
           if (ndx = index_of(interaction))
              @interactions[ndx] = interaction
           else
              @interactions << interaction
           end
        end
      end

      class MergingInteractionsFilter < InteractionsFilter
        def << interaction
          if (ndx = index_of(interaction))
            if same_same_but_different?(@interactions[ndx], interaction)
              message = Interactions::InteractionDiffMessage.new(@interactions[ndx], interaction).to_s
              raise SameSameButDifferentError, message
            end
            @interactions[ndx] = interaction
          else
            @interactions << interaction
          end
        end

        def same_same_but_different?(existing_interaction, new_interaction)
          existing_interaction != new_interaction
        end
      end
    end
  end
end
