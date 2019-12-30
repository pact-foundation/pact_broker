module PactBroker
  module Matrix
    class QueryBuilder
      def self.provider_or_provider_version_matches_selectors(selectors, allow_null_provider_version = false, qualifier)
        most_specific_criteria = selectors.collect(&:most_specific_provider_criterion)

        provider_version_ids = collect_ids(most_specific_criteria, :pacticipant_version_id)
        provider_ids = collect_ids(most_specific_criteria, :pacticipant_id)

        ors = []
        ors << { Sequel[qualifier][:provider_version_id] => provider_version_ids } if provider_version_ids.any?
        ors << { Sequel[qualifier][:provider_id] => provider_ids } if provider_ids.any?

        if allow_null_provider_version
          ors << {
            Sequel[:lp][:provider_id] => selectors.collect{ |s| s[:pacticipant_id] },
            Sequel[qualifier][:provider_version_id] => nil
          }
        end

        Sequel.|(*ors)
      end

      def self.consumer_in_pacticipant_ids(selectors)
        { consumer_id: selectors.collect(&:pacticipant_id) }
      end

      def self.consumer_or_consumer_version_or_pact_publication_in(selectors, qualifier)
        most_specific_criteria = selectors.collect(&:most_specific_consumer_criterion)
        consumer_version_ids = collect_ids(most_specific_criteria, :pacticipant_version_id)
        consumer_ids = collect_ids(most_specific_criteria, :pacticipant_id)

        ors = []
        ors << { Sequel[qualifier][:consumer_version_id] => consumer_version_ids } if consumer_version_ids.any?
        ors << { Sequel[qualifier][:consumer_id] => consumer_ids } if consumer_ids.any?

        Sequel.|(*ors)
      end

      # Some selecters are specified in the query, others are implied (when only one pacticipant is specified,
      # the integrations are automatically worked out, and the selectors for these are of type :implied )
      # When there are 3 pacticipants that each have dependencies on each other (A->B, A->C, B->C), the query
      # to deploy C (implied A, implied B, specified C) was returning the A->B row because it matched the
      # implied selectors as well.
      # This extra filter makes sure that every row that is returned actually matches one of the specified
      # selectors.
      def self.either_consumer_or_provider_was_specified_in_query(selectors, qualifier = nil)
        consumer_id_field = qualifier ? Sequel[qualifier][:consumer_id] : CONSUMER_ID
        provider_id_field = qualifier ? Sequel[qualifier][:provider_id] : PROVIDER_ID
        specified_pacticipant_ids = selectors.select(&:specified?).collect(&:pacticipant_id)
        Sequel.|({ consumer_id_field => specified_pacticipant_ids } , { provider_id_field => specified_pacticipant_ids })
      end

      def self.consumer_or_consumer_version_or_provider_or_provider_or_provider_version_match_selector(s)
        consumer_or_consumer_version_match = s[:pacticipant_version_id] ? { Sequel[:lp][:consumer_version_id] => s[:pacticipant_version_id] } :  { Sequel[:lp][:consumer_id] => s[:pacticipant_id] }
        provider_or_provider_version_match = s[:pacticipant_version_id] ? { Sequel[:lv][:provider_version_id] => s[:pacticipant_version_id] } :  { Sequel[:lp][:provider_id] => s[:pacticipant_id] }
        Sequel.|(consumer_or_consumer_version_match , provider_or_provider_version_match)
      end

      def self.all_pacticipant_ids selectors
        selectors.collect(&:pacticipant_id)
      end

      def self.collect_ids(hashes, key)
        hashes.collect{ |s| s[key] }.flatten.compact
      end

      def self.collect_the_ids selectors
        most_specific_criteria = selectors.collect(&:most_specific_consumer_criterion)
        pacticipant_version_ids = collect_ids(most_specific_criteria, :pacticipant_version_id)
        pacticipant_ids = collect_ids(most_specific_criteria, :pacticipant_id)
        all_pacticipant_ids = selectors.collect(&:pacticipant_id)

        specified_pacticipant_ids = selectors.select(&:specified?).collect(&:pacticipant_id)

        {
          consumer_version_ids: pacticipant_version_ids,
          provider_version_ids: pacticipant_version_ids,
          consumer_ids: pacticipant_ids,
          provider_ids: pacticipant_ids,
          all_pacticipant_ids: all_pacticipant_ids,
          specified_pacticipant_ids: specified_pacticipant_ids
        }
      end
    end
  end
end