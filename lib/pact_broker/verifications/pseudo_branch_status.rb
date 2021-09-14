# The time ordered list of pacts that belong to the same consumer/provider/tag
# (or just consumer/provider) can be considered a pseudo branch.

# The concept of "stale" (the pact used to be verified but then it changed and we haven't got
# a new verification result yet) only really make sense if we're trying to summarise
# the state of an integration or pseudo branch. Once we start showing multiple pacts for each
# integration (ie. the latest for each tag) then each pact version is either verified,
# or it's not verified.

module PactBroker
  module Verifications
    class PseudoBranchStatus
      def initialize latest_pact, latest_verification
        @latest_pact = latest_pact
        @latest_verification = latest_verification
      end

      def to_s
        to_sym.to_s
      end

      def to_sym
        return :never unless latest_pact
        return :never unless ever_verified?
        if latest_verification_successful?
          if pact_changed_since_last_verification?
            :stale
          else
            :success
          end
        elsif latest_verification.failed_and_pact_pending?
          :failed_pending
        else
          :failed
        end
      end

      private

      attr_reader :latest_pact, :latest_verification

      def latest_verification_successful?
        latest_verification.success
      end

      def pact_changed_since_last_verification?
        latest_verification.pact_version_sha != latest_pact.pact_version_sha
      end

      def ever_verified?
        !!latest_verification
      end
    end
  end
end
