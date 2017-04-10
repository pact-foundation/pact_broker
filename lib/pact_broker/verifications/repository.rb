require 'sequel'
require 'pact_broker/domain/verification'

module PactBroker
  module Verifications
    class Repository

      include PactBroker::Repositories::Helpers

      def verification_count_for_pact pact
        PactBroker::Domain::Verification.where(pact_id: pact.id).count
      end
    end
  end
end
