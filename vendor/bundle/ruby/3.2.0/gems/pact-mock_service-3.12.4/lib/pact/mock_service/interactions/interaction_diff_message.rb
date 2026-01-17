require 'pact/shared/json_differ'
require 'pact/mock_service/interaction_decorator'

module Pact
  module MockService
    module Interactions
      class InteractionDiffMessage

        def initialize previous_interaction, new_interaction
          @previous_interaction = previous_interaction
          @new_interaction = new_interaction
        end

        def to_s
          "An interaction with same description (#{new_interaction.description.inspect}) and provider state (#{new_interaction.provider_state.inspect}) but a different #{differences} has already been used. Please use a different description or provider state, or remove any random data in the interaction."
        end

        private

        attr_reader :previous_interaction, :new_interaction

        def differences
          diff = Pact::JsonDiffer.call(previous_interaction_hash, new_interaction_hash, allow_unexpected_keys: false)
          diff.keys.collect do | parent_key |
            diff[parent_key].keys.collect do | child_key |
              "#{parent_key} #{child_key}"
            end
          end.flatten.join(", ").reverse.sub(",", "dna ").reverse
        end

        def previous_interaction_hash
          raw_hash previous_interaction
        end

        def new_interaction_hash
          raw_hash new_interaction
        end

        def raw_hash interaction
          JSON.parse(Pact::MockService::InteractionDecorator.new(interaction).to_json)
        end
      end
    end
  end
end
