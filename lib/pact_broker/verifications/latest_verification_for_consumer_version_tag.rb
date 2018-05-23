require 'pact_broker/domain/verification'

module PactBroker
  module Verifications
    class LatestVerificationForConsumerVersionTag < PactBroker::Domain::Verification
      set_dataset(:latest_verifications_for_consumer_version_tags)
    end
  end
end