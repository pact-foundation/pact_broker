require 'pact_broker/pacts/latest_pact_publications_by_consumer_version'
require 'pact_broker/pacts/head_pact'

module PactBroker
  module Pacts

    # latest pact for each consumer/provider pair
    class LatestPactPublications < LatestPactPublicationsByConsumerVersion
      set_dataset(:latest_pact_publications)

      # def dataset_module
      #   def where_age_less_than(days)
      #     start_date = Date.today - days
      #     where{ latest_pact_publications[:created_at] >= start_date }
      #   end

      #   def for_selector(selector)
      #     query = self
      #     query = query.where(consumer_name: selector.pacticipant_name) if selector.pacticipant_name
      #     query = query.where(tag_name: selector.tag) if selector.tag && selector.tag.is_a?(String)
      #     query = query.where_age_less_than(selector.max_age) if selector.max_age
      #     query
      #   end
      # end

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
