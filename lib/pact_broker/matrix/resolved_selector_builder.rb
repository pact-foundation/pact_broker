# Builds a PactBroker::Matrix::UnresolvedSelector based on the given
# UnresolvedSelector, selector type, Pacticipant and Version objects,
# using the selector_ignorer to work out if the built ResolvedSelector
# should be marked as ignored or not.

module PactBroker
  module Matrix
    class ResolvedSelectorBuilder

      attr_accessor :pacticipant, :versions

      # @param [PactBroker::Matrix::UnresolvedSelector] unresolved_selector
      # @param [Symbol] selector_type :specified or :inferred
      # @param [PactBroker::Matrix::Ignorer] selector_ignorer
      def initialize(unresolved_selector, selector_type, selector_ignorer)
        @unresolved_selector = unresolved_selector
        @selector_type = selector_type
        @selector_ignorer = selector_ignorer
      end

      def build
        if pacticipant && versions
          build_resolved_selectors_for_versions(pacticipant, versions, unresolved_selector, selector_type)
        elsif pacticipant
          selector_for_all_versions_of_a_pacticipant(pacticipant, unresolved_selector, selector_type)
        else
          build_selector_for_non_existing_pacticipant(unresolved_selector, selector_type)
        end
      end

      private

      attr_reader :unresolved_selector, :selector_type, :selector_ignorer

      # When a single selector specifies multiple versions (eg. "all prod pacts"), this expands
      # the single selector into one selector for each version.
      # When a pacticipant is found, but there are no versions matching the selector,
      # the versions array will be have a single item which is nil (`[nil]`).
      # See PactBroker::Matrix::SelectorResolver#find_versions_for_selector
      # There may be a better way to pass in this information.
      def build_resolved_selectors_for_versions(pacticipant, versions, unresolved_selector, selector_type)
        one_of_many = versions.compact.size > 1
        versions.collect do | version |
          if version
            selector_for_found_version(pacticipant, version, unresolved_selector, selector_type, one_of_many)
          else
            selector_for_non_existing_version(pacticipant, unresolved_selector, selector_type)
          end
        end
      end

      def selector_for_non_existing_version(pacticipant, unresolved_selector, selector_type)
        ignore = selector_ignorer.ignore_pacticipant?(pacticipant)
        ResolvedSelector.for_pacticipant_and_non_existing_version(pacticipant, unresolved_selector, selector_type, ignore)
      end

      def selector_for_found_version(pacticipant, version, unresolved_selector, selector_type, one_of_many)
        ResolvedSelector.for_pacticipant_and_version(
          pacticipant,
          version,
          unresolved_selector,
          selector_type,
          selector_ignorer.ignore_pacticipant_version?(pacticipant, version),
          one_of_many
        )
      end

      def selector_for_all_versions_of_a_pacticipant(pacticipant, unresolved_selector, selector_type)
        ResolvedSelector.for_pacticipant(
          pacticipant,
          unresolved_selector,
          selector_type,
          selector_ignorer.ignore_pacticipant?(pacticipant)
        )
      end

      # only relevant for ignore selectors, validation stops this happening for the normal
      # selectors
      def build_selector_for_non_existing_pacticipant(unresolved_selector, selector_type)
        ResolvedSelector.for_non_existing_pacticipant(unresolved_selector, selector_type, false)
      end
    end
  end
end