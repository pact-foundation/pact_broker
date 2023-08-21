require "pact_broker/matrix/selector_resolver"

# Builds the array of ResolvedSelector objects using the
# ignore selectors, the specified selectors, and the inferred integrations.

module PactBroker
  module Matrix
    class ResolvedSelectorsBuilder
      attr_reader :ignore_selectors, :specified_selectors, :inferred_selectors

      def initialize
        @inferred_selectors = []
      end

      # @param [Array<PactBroker::Matrix::UnresolvedSelector>]
      # @param [Hash] options
      def resolve_selectors(unresolved_specified_selectors, unresolved_ignore_selectors)
        # must do this first because we need the ignore selectors to resolve the specified selectors
        @ignore_selectors = SelectorResolver.resolved_ignore_selectors(unresolved_ignore_selectors)
        @specified_selectors = SelectorResolver.resolve_specified_selectors(unresolved_specified_selectors, ignore_selectors)
      end

      # Use the given Integrations to work out what the selectors are for the versions that the versions for the specified
      # selectors should be deployed with.
      # eg. For `can-i-deploy --pacticipant Foo --version adfjkwejr --to-environment prod`, work out the selectors for the integrated application
      # versions in the prod environment.
      # @param [Array<PactBroker::Matrix::Integration>] integrations
      def resolve_inferred_selectors(integrations, options)
        @inferred_selectors = SelectorResolver.resolve_inferred_selectors(specified_selectors, ignore_selectors, integrations, options)
      end

      # All the resolved selectors to be used in the matrix query, specified and inferred (if any)
      # @return [Array<PactBroker::Matrix::ResolvedSelector>]
      def all_selectors
        specified_selectors + inferred_selectors
      end
    end
  end
end
