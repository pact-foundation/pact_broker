module PactBroker
  module Matrix
    class QueryBuilder
      def self.provider_or_provider_version_matches(query_ids, provider_version_qualifier = nil, provider_qualifier = nil)
        Sequel.|(*provider_or_provider_version_criteria(query_ids, provider_version_qualifier, provider_qualifier))
      end

      def self.provider_matches(query_ids, qualifier)
        {
          qualify(qualifier, :provider_id) => query_ids.pacticipant_ids,
        }
      end

      def self.provider_or_provider_version_matches_or_pact_unverified(query_ids, provider_version_qualifier = nil, provider_qualifier = nil)
        ors = provider_or_provider_version_criteria(query_ids, provider_version_qualifier, provider_qualifier)

        # If we have specified any versions, then we need to add an
        # "OR (provider matches these IDs and provider version is null)"
        # so that we get a line with blank verification details.
        if query_ids.pacticipant_version_ids.any?
          ors << {
            qualify(provider_qualifier, :provider_id) => query_ids.all_pacticipant_ids,
            qualify(provider_version_qualifier, :provider_version_id) => nil
          }
        end

        Sequel.|(*ors)
      end

      def self.provider_or_provider_version_criteria(query_ids, provider_version_qualifier = nil, provider_qualifier = nil)
        ors = []
        ors << { qualify(provider_version_qualifier, :provider_version_id) => query_ids.pacticipant_version_ids } if query_ids.pacticipant_version_ids.any?
        ors << { qualify(provider_qualifier, :provider_id) => query_ids.pacticipant_ids } if query_ids.pacticipant_ids.any?
        ors
      end

      def self.consumer_in_pacticipant_ids(query_ids)
        { consumer_id: query_ids.all_pacticipant_ids }
      end

      def self.consumer_or_consumer_version_matches(query_ids, qualifier)
        ors = []
        ors << { qualify(qualifier, :consumer_version_id) => query_ids.pacticipant_version_ids } if query_ids.pacticipant_version_ids.any?
        ors << { qualify(qualifier, :consumer_id) => query_ids.pacticipant_ids } if query_ids.pacticipant_ids.any?

        Sequel.|(*ors)
      end

      # Some selecters are specified in the query, others are implied (when only one pacticipant is specified,
      # the integrations are automatically worked out, and the selectors for these are of type :implied )
      # When there are 3 pacticipants that each have dependencies on each other (A->B, A->C, B->C), the query
      # to deploy C (implied A, implied B, specified C) was returning the A->B row because it matched the
      # implied selectors as well.
      # This extra filter makes sure that every row that is returned actually matches one of the specified
      # selectors.
      def self.either_consumer_or_provider_was_specified_in_query(query_ids, qualifier = nil)
        Sequel.|({
          qualify(qualifier, :consumer_id) => query_ids.specified_pacticipant_ids
        } , {
          qualify(qualifier, :provider_id) => query_ids.specified_pacticipant_ids
        })
      end

      # QueryIds is built from a single selector, so there is only one pacticipant_id or pacticipant_version_id
      def self.consumer_or_consumer_version_or_provider_or_provider_or_provider_version_match(query_ids, pacts_qualifier = :p, verifications_qualifier = :v)
        ors = if query_ids.pacticipant_version_id
          [
            { Sequel[pacts_qualifier][:consumer_version_id] => query_ids.pacticipant_version_id },
            { Sequel[verifications_qualifier][:provider_version_id] => query_ids.pacticipant_version_id }
          ]
        else
          [
            { Sequel[pacts_qualifier][:consumer_id] => query_ids.pacticipant_id },
            { Sequel[pacts_qualifier][:provider_id] => query_ids.pacticipant_id }
          ]
        end

        Sequel.|(*ors)
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
