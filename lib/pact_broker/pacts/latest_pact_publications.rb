require 'pact_broker/pacts/latest_pact_publications_by_consumer_version'
require 'pact_broker/pacts/head_pact'

module PactBroker
  module Pacts

    # latest pact for each consumer/provider pair
    class LatestPactPublications < LatestPactPublicationsByConsumerVersion
      set_dataset(:latest_pact_publications)

      # This pact may well be the latest for certain tags, but in this query
      # we don't know what they are
      def to_domain
        HeadPact.new(super, consumer_version_number, nil)
      end
    end
  end
end

# Table: latest_pact_publications
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
