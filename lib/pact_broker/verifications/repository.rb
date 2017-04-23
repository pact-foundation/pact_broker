require 'sequel'
require 'pact_broker/domain/verification'

module PactBroker
  module Verifications
    class Repository

      include PactBroker::Repositories::Helpers

      class LatestVerifications < PactBroker::Domain::Verification
        set_dataset(:latest_verifications)
      end

      def verification_count_for_pact pact
        PactBroker::Domain::Verification.where(pact_publication_id: pact.id).count
      end

      def find_latest_verifications_for_consumer_version consumer_name, consumer_version_number
        LatestVerifications
          .join(PactBroker::Pacts::AllPacts, id: :pact_publication_id)
          .where(name_like(:consumer_name, consumer_name))
          .where(consumer_version_number: consumer_version_number)
          .order(:provider_name)
      end
    end
  end
end
