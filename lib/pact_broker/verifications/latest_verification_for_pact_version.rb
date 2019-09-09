require 'pact_broker/domain/verification'

module PactBroker
  module Verifications
    class LatestVerificationForPactVersion < PactBroker::Domain::Verification
      set_dataset(:latest_verifications_for_pact_versions)

      # this view doesn't have a consumer_id
      # TODO add it
      def consumer
        PactBroker::Domain::Pacticipant.find(id: PactBroker::Pacts::AllPactPublications
           .where(pact_version_id: pact_version_id)
           .limit(1).select(:consumer_id))
      end

      # this view doesn't have a provider_id
      # TODO add it
      def provider
        PactBroker::Domain::Pacticipant.find(id: PactBroker::Pacts::AllPactPublications
           .where(pact_version_id: pact_version_id)
           .limit(1).select(:provider_id))
      end
    end
  end
end

# Table: latest_verifications_for_pact_versions
# Columns:
#  id                      | integer                     |
#  number                  | integer                     |
#  success                 | boolean                     |
#  build_url               | text                        |
#  pact_version_id         | integer                     |
#  execution_date          | timestamp without time zone |
#  created_at              | timestamp without time zone |
#  provider_version_id     | integer                     |
#  provider_version_number | text                        |
#  provider_version_order  | integer                     |
#  test_results            | text                        |
