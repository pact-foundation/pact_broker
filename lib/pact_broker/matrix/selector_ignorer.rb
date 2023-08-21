# This class determines whether or not a resolved selector (both specified and inferred)
# that is about to be created should be marked as "ignored".
# It uses the ignore selectors are provided in the can-i-deploy CLI command like so:
#   can-i-deploy --pacticipant Foo --version 234243 --to-environment prod --ignore SomeProviderThatIsNotReadyYet [--version SomeOptionalVersion]
# The ignored flag on the ResolvedSelector is used to determine whether or not a failing/missing row
# in the can-i-deploy matrix should be ignored.
# This allows can-i-deploy to pass successfully when a dependency is known to be not ready,
# but the developer wants to deploy the application anyway.

# The only reason why we need to resolve the ignore selectors is that we check in PactBroker::Matrix::DeploymentStatusSummary
# whether or not the pacticipant or version they specify actually exist.
# We could actually have performed the ignore checks just using the name and version number.

module PactBroker
  module Matrix
    class SelectorIgnorer

      # @param [Array<PactBroker::Matrix::UnresolvedSelector>] resolved_ignore_selectors
      def initialize(resolved_ignore_selectors)
        @resolved_ignore_selectors = resolved_ignore_selectors
      end

      # Whether the pacticipant should be ignored if the verification results are missing/failed.
      # @param [PactBroker::Domain::Pacticipant] pacticipant
      # @return [Boolean]
      def ignore_pacticipant?(pacticipant)
        resolved_ignore_selectors.any? do | s |
          s.pacticipant_id == pacticipant.id && s.only_pacticipant_name_specified?
        end
      end

      # Whether the pacticipant version should be ignored if the verification results are missing/failed.
      # @param [PactBroker::Domain::Pacticipant] pacticipant
      # @param [PactBroker::Domain::Version] version
      # @return [Boolean]
      def ignore_pacticipant_version?(pacticipant, version)
        resolved_ignore_selectors.any? do | s |
          s.pacticipant_id == pacticipant.id && (s.only_pacticipant_name_specified? || s.pacticipant_version_id == version.id)
        end
      end

      private

      attr_reader :resolved_ignore_selectors
    end

    # Used when resolving the ignore selecors in the first place - the process for resolving normal selectors
    # and ignore selectors is almost the same, but it makes no sense to ignore an ignore selector.
    class NilSelectorIgnorer
      def ignore_pacticipant?(*)
        false
      end

      def ignore_pacticipant_version?(*)
        false
      end
    end
  end
end
