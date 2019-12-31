module PactBroker
  module Matrix
    class QueryBuilder
      def self.provider_or_provider_version_matches(selectors, qualifier = nil)
        Sequel.|(*provider_or_provider_version_criteria(selectors, qualifier))
      end

      def self.provider_or_provider_version_matches_or_pact_unverified(selectors, qualifier = nil)
        ors = provider_or_provider_version_criteria(selectors, qualifier)
        all_provider_ids = selectors.collect{ |s| s[:pacticipant_id] }
        ors << {
          qualify(:lp, :provider_id) => all_provider_ids,
          qualify(qualifier, :provider_version_id) => nil
        }
        Sequel.|(*ors)
      end

      def self.provider_or_provider_version_criteria(selectors, qualifier = nil)
        most_specific_criteria = selectors.collect(&:most_specific_criterion)
        # the pacticipant version ids for selectors where pacticipant version id was the most specific criterion
        pacticipant_version_ids = collect_ids(most_specific_criteria, :pacticipant_version_id)
        # the pacticipant ids for the selectors where the pacticipant id was most specific criterion
        pacticipant_ids = collect_ids(most_specific_criteria, :pacticipant_id)

        ors = []
        ors << { qualify(qualifier, :provider_version_id) => pacticipant_version_ids } if pacticipant_version_ids.any?
        ors << { qualify(qualifier, :provider_id) => pacticipant_ids } if pacticipant_ids.any?
        ors
      end

      def self.consumer_in_pacticipant_ids(selectors)
        { consumer_id: selectors.collect(&:pacticipant_id) }
      end

      def self.consumer_or_consumer_version_matches(selectors, qualifier)
        most_specific_criteria = selectors.collect(&:most_specific_criterion)
        # the pacticipant version ids for selectors where pacticipant version id was the most specific criterion
        pacticipant_version_ids = collect_ids(most_specific_criteria, :pacticipant_version_id)
        # the pacticipant ids for the selectors where the pacticipant id was most specific criterion
        pacticipant_ids = collect_ids(most_specific_criteria, :pacticipant_id)

        ors = []
        ors << { qualify(qualifier, :consumer_version_id) => pacticipant_version_ids } if pacticipant_version_ids.any?
        ors << { qualify(qualifier, :consumer_id) => pacticipant_ids } if pacticipant_ids.any?

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
        specified_pacticipant_ids = selectors.select(&:specified?).collect(&:pacticipant_id)
        Sequel.|({
          qualify(qualifier, :consumer_id) => specified_pacticipant_ids
        } , {
          qualify(qualifier, :provider_id) => specified_pacticipant_ids
        })
      end

      def self.consumer_or_consumer_version_or_provider_or_provider_or_provider_version_match(s)
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
        most_specific_criteria = selectors.collect(&:most_specific_criterion)
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

      def self.qualify(qualifier, column)
        if qualifier
          Sequel[qualifier][column]
        else
          column
        end
      end
    end
  end
end
