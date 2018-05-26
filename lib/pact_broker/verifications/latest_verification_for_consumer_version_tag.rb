require 'pact_broker/domain/verification'

module PactBroker
  module Verifications
    class LatestVerificationForConsumerVersionTag < PactBroker::Domain::Verification
      set_dataset(:latest_verifications_for_consumer_version_tags)

      # Don't need to load the pact_version as we do in the superclass,
      # as pact_version_sha is included in the view for convenience
      def pact_version_sha
        values[:pact_version_sha]
      end

      def provider_version_number
        values[:provider_version_number]
      end

      def provider_version_order
        values[:provider_version_order]
      end
    end
  end
end
