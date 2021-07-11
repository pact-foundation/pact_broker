require "pact_broker/domain/verification"

# TODO replace this with a dynamic model, not backed by a view

module PactBroker
  module Verifications
    class LatestVerificationForPactVersion < PactBroker::Domain::Verification
      set_dataset(:latest_verifications_for_pact_versions)
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
