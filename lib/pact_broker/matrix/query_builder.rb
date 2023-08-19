module PactBroker
  module Matrix
    class QueryBuilder
      def self.provider_or_provider_version_matches(query_ids, provider_version_qualifier = nil, provider_qualifier = nil)
        Sequel.|(*provider_or_provider_version_criteria(query_ids, provider_version_qualifier, provider_qualifier))
      end

      def self.provider_matches(query_ids, qualifier)
        {
          qualify(qualifier, :provider_id) => query_ids.pacticipant_ids
        }
      end

      def self.provider_or_provider_version_criteria(query_ids, provider_version_qualifier = nil, provider_qualifier = nil)
        ors = []
        ors << { qualify(provider_version_qualifier, :provider_version_id) => query_ids.pacticipant_version_ids } if query_ids.pacticipant_version_ids.any?
        ors << { qualify(provider_qualifier, :provider_id) => query_ids.pacticipant_ids } if query_ids.pacticipant_ids.any?
        ors
      end

      def self.consumer_matches(query_ids, qualifier)
        {
          qualify(qualifier, :consumer_id) => query_ids.pacticipant_ids
        }
      end

      def self.consumer_or_consumer_version_matches(query_ids, qualifier)
        ors = []
        ors << { qualify(qualifier, :consumer_version_id) => query_ids.pacticipant_version_ids } if query_ids.pacticipant_version_ids.any?
        ors << { qualify(qualifier, :consumer_id) => query_ids.pacticipant_ids } if query_ids.pacticipant_ids.any?

        Sequel.|(*ors)
      end

      # Some selecters are specified in the query, others are inferred (when only one pacticipant is specified,
      # the integrations are automatically worked out, and the selectors for these are of type :inferred )
      # When there are 3 pacticipants that each have dependencies on each other (A->B, A->C, B->C), the query
      # to deploy C (inferred A, inferred B, specified C) was returning the A->B row because it matched the
      # inferred selectors as well.
      # This extra filter makes sure that every row that is returned actually matches one of the specified
      # selectors.
      def self.either_consumer_or_provider_was_specified_in_query(query_ids, qualifier = nil)
        Sequel.|({
          qualify(qualifier, :consumer_id) => query_ids.specified_pacticipant_ids
        } , {
          qualify(qualifier, :provider_id) => query_ids.specified_pacticipant_ids
        })
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
