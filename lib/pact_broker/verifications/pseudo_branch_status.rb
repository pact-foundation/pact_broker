# The time ordered list of pacts that belong to the same consumer/provider/tag
# (or just consumer/provider) can be considered a pseudo branch.

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
