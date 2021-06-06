require "pact_broker/domain/verification"

module PactBroker
  module Verifications

    include PactBroker::Repositories::Helpers

    class LatestVerificationForConsumerAndProvider < PactBroker::Domain::Verification
      set_dataset(:latest_verifications_for_consumer_and_provider)

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

# Table: latest_verifications_for_consumer_and_provider
# Columns:
#  consumer_id             | integer                     |
#  provider_id             | integer                     |
#  pact_version_sha        | text                        |
#  provider_version_number | text                        |
#  provider_version_order  | integer                     |
#  id                      | integer                     |
#  number                  | integer                     |
#  success                 | boolean                     |
#  provider_version        | text                        |
#  build_url               | text                        |
#  pact_version_id         | integer                     |
#  execution_date          | timestamp without time zone |
#  created_at              | timestamp without time zone |
#  provider_version_id     | integer                     |
#  test_results            | text                        |
