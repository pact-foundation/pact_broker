module PactBroker
  module Matrix
    class Reason
      def == other
        self.class == other.class
      end
    end

    class ErrorReason < Reason; end

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

      def to_s
        "#{self.class} consumer_selector=#{consumer_selector}, provider_selector=#{provider_selector}"
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

      def to_s
        "#{self.class} selector=#{selector}"
      end
    end

    # The pact for the required consumer version has been
    # successfully verified by the required provider version
    class Successful < Reason
    end

    # There aren't any rows, but there are also no missing
    # provider verifications.
    class NoDependenciesMissing < Reason
    end
  end
end
