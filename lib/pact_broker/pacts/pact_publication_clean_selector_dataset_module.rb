module PactBroker
  module Pacts
    module PactPublicationCleanSelectorDatasetModule
      # we've already done the latest_by_consumer_tag in the clean
      def latest_by_consumer_tag_for_clean_selector(selector)
        query = latest_by_consumer_tag
        query = query.for_consumer_name(selector.pacticipant_name) if selector.pacticipant_name
        query = query.for_consumer_version_tag(selector.tag) if selector.tag && selector.tag.is_a?(String)
        query = query.where_age_less_than(selector.max_age) if selector.max_age
        query
      end

      def where_age_less_than(days)
        start_date = Date.today - days
        where{ pact_publications[:created_at] >= start_date }
      end
    end
  end
end
