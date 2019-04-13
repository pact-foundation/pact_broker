require 'pact_broker/domain/verification'

module PactBroker
  module Verifications
    include PactBroker::Repositories::Helpers

    class AllVerifications < PactBroker::Domain::Verification
      set_dataset(:all_verifications)
    end

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

# Table: all_verifications
# Columns:
#  id                      | integer                     |
#  number                  | integer                     |
#  success                 | boolean                     |
#  provider_version_id     | integer                     |
#  provider_version_number | text                        |
#  provider_version_order  | integer                     |
#  build_url               | text                        |
#  pact_version_id         | integer                     |
#  execution_date          | timestamp without time zone |
#  created_at              | timestamp without time zone |
