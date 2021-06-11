require "pact_broker/domain/version"

module PactBroker
  module Versions
    include PactBroker::Repositories::Helpers

    class LatestVersion < PactBroker::Domain::Version
      set_dataset(:latest_versions)
    end
  end
end

# Table: latest_versions
# Columns:
#  id             | integer                     |
#  number         | text                        |
#  repository_ref | text                        |
#  pacticipant_id | integer                     |
#  order          | integer                     |
#  created_at     | timestamp without time zone |
#  updated_at     | timestamp without time zone |
