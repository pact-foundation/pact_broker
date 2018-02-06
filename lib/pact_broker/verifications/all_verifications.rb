require 'pact_broker/domain/verification'

module PactBroker
  module Verifications
    include PactBroker::Repositories::Helpers

    class AllVerifications < PactBroker::Domain::Verification
      set_dataset(:all_verifications)
    end

  end
end
