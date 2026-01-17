require 'pact/mock_service/interactions/expected_interactions'
require 'pact/mock_service/interactions/actual_interactions'
require 'pact/mock_service/interactions/verified_interactions'
require 'pact/mock_service/interaction_decorator'
require 'pact/mock_service/interactions/interaction_diff_message'
require 'pact/mock_service/errors'

module Pact
  module MockService
    class Session

      attr_reader :expected_interactions, :actual_interactions, :verified_interactions, :consumer_contract_details, :logger

      def initialize options
        @pact_written = false
        @logger = options[:logger]
        @expected_interactions = Interactions::ExpectedInteractions.new
        @actual_interactions = Interactions::ActualInteractions.new
        @verified_interactions = Interactions::VerifiedInteractions.new
        @warn_on_too_many_interactions = options[:warn_on_too_many_interactions] || false
        @max_concurrent_interactions_before_warning = get_max_concurrent_interactions_before_warning
        @consumer_contract_details = {
          pact_dir: options[:pact_dir],
          consumer: {name: options[:consumer]},
          provider: {name: options[:provider]},
          interactions: verified_interactions,
          pact_specification_version: options[:pact_specification_version],
          pactfile_write_mode: options[:pactfile_write_mode]
        }
      end

      def pact_written?
        @pact_written
      end

      def record_pact_written
        @pact_written = true
      end

      def set_expected_interactions interactions
        clear_expected_and_actual_interactions
        interactions.each do | interaction |
          add_expected_interaction interaction
        end
      end

      def clear_expected_and_actual_interactions
        expected_interactions.clear
        actual_interactions.clear
      end

      def clear_all
        expected_interactions.clear
        actual_interactions.clear
        verified_interactions.clear
        @pact_written = false
      end

      def add_expected_interaction interaction
        if (previous_interaction = interaction_already_verified_with_same_description_and_provider_state_but_not_equal(interaction))
          handle_almost_duplicate_interaction previous_interaction, interaction
        else
          really_add_expected_interaction interaction
        end
      end

      private

      attr_reader :warn_on_too_many_interactions, :max_concurrent_interactions_before_warning

      def really_add_expected_interaction interaction
        expected_interactions << interaction
        logger.info "Registered expected interaction #{interaction.request.method_and_path}"
        logger.debug JSON.pretty_generate InteractionDecorator.new(interaction)
        if warn_on_too_many_interactions && expected_interactions.size > max_concurrent_interactions_before_warning
          logger.warn "You currently have #{expected_interactions.size} interactions mocked at the same time. This suggests the scope of your consumer tests is larger than recommended, and you may find them hard to debug and maintain. See https://pact.io/too-many-interactions for more information."
        end
      end

      def handle_almost_duplicate_interaction previous_interaction, interaction
        message = Interactions::InteractionDiffMessage.new(previous_interaction, interaction).to_s
        logger.error message
        raise SameSameButDifferentError, message
      end

      def interaction_already_verified_with_same_description_and_provider_state_but_not_equal interaction
        other = verified_interactions.find_matching_description_and_provider_state interaction
        other && other != interaction ? other : nil
      end

      def get_max_concurrent_interactions_before_warning
        ENV['PACT_MAX_CONCURRENT_INTERACTIONS_BEFORE_WARNING'] ? ENV['PACT_MAX_CONCURRENT_INTERACTIONS_BEFORE_WARNING'].to_i : 3
      end
    end
  end
end
