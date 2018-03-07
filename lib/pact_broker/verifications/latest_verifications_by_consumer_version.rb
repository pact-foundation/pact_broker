require 'pact_broker/domain/verification'

module PactBroker
  module Verifications
    class Repository

      include PactBroker::Repositories::Helpers

      # TODO rename this to LatestVerificationsByPactVersion
      class LatestVerificationsByConsumerVersion < PactBroker::Domain::Verification
        set_dataset(:latest_verifications)
      end
    end
  end
end
