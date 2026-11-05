module PactBroker
  module Matrix

    class Reason
      def == other
        self.class == other.class
      end

      def type
        :info
      end
    end

    class ErrorReason < Reason
      def selectors
        raise NotImplementedError
      end

      def type
        :error
      end
    end

    class ErrorReasonWithTwoSelectors < ErrorReason
      attr_reader :consumer_selector, :provider_selector

      def initialize(consumer_selector, provider_selector)
        @consumer_selector = consumer_selector
        @provider_selector = provider_selector
      end

      def == other
        super(other) &&
          consumer_selector == other.consumer_selector &&
          provider_selector == other.provider_selector
      end
    end

    # The pact for the required consumer version
    # has never been verified by the provider
    # (a row in the matrix with a blank provider version)
    class PactNotEverVerifiedByProvider < ErrorReasonWithTwoSelectors; end

    # The pact for the required consumer verison
    # has been verified by the provider, but not by
    # the required provider version
    # (this row is not included in the matrix, and it's
    # absence must be inferred)
    # Update: because the left outer join now returns a row with blank verification
    # details, this scenario is now indistingishable from PactNotEverVerifiedByProvider
    # TODO: merge these two classes when it's verified that they are duplicates.
    class PactNotVerifiedByRequiredProviderVersion < ErrorReasonWithTwoSelectors; end

    # The pact verification has failed
    class VerificationFailed < ErrorReasonWithTwoSelectors; end

    class VerificationFailedWithRow < ErrorReasonWithTwoSelectors; end

    # The specified pacticipant version does not exist
    class SpecifiedVersionDoesNotExist < ErrorReason
      attr_reader :selector

      def initialize(selector)
        @selector = selector
      end

      def == other
        super(other) && selector == other.selector
      end
    end

    class Warning < Reason
      def selectors
        raise NotImplementedError
      end

      def type
        :warning
      end
    end

    class IgnoreSelectorDoesNotExist < Warning
      attr_reader :selector

      def initialize(selector)
        @selector = selector
      end

      def == other
        super(other) && selector == other.selector
      end
    end

    class NoEnvironmentSpecified < Warning; end

    class SelectorWithoutPacticipantVersionNumberSpecified < Warning; end

    # The pact for the required consumer version has been
    # successfully verified by the required provider version
    class Successful < Reason
      def type
        :success
      end
    end

    # There aren't any rows, but there are also no missing
    # provider verifications.
    class NoDependenciesMissing < Reason
      def type
        :success
      end
    end

    class InteractionsMissingVerifications < ErrorReasonWithTwoSelectors
      attr_reader :interactions

      def initialize(consumer_selector, provider_selector, interactions)
        super(consumer_selector, provider_selector)
        @interactions = interactions
      end
    end
  end
end
