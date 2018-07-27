require 'pact_broker/domain/verification'

module PactBroker
  module Verifications
    include PactBroker::Repositories::Helpers

    class AllVerifications < PactBroker::Domain::Verification
      set_dataset(:all_verifications)
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
