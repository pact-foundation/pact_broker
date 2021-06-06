require "pact_broker/pacts/all_pact_publications"

module PactBroker
  module Pacts

    class LatestPactPublicationsByConsumerVersion < AllPactPublications
      set_dataset(:latest_pact_publications_by_consumer_versions)
    end

  end
end

# Table: latest_pact_publications_by_consumer_versions
# Columns:
#  id                      | integer                     |
#  consumer_id             | integer                     |
#  consumer_name           | text                        |
#  consumer_version_id     | integer                     |
#  consumer_version_number | text                        |
#  consumer_version_order  | integer                     |
#  provider_id             | integer                     |
#  provider_name           | text                        |
#  revision_number         | integer                     |
#  pact_version_id         | integer                     |
#  pact_version_sha        | text                        |
#  created_at              | timestamp without time zone |
