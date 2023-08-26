module PactBroker
  module Matrix
    module IntegrationDatasetModule
      def select_distinct_pacticipant_ids
        select_pacticipant_ids.distinct
      end

      # Return the distinct consumer/provider ids and names for the integrations which involve the given resolved selector
      # in the role of consumer. The resolved selector must have a pacticipant_id, and may or may not have a pacticipant_version_id.
      # @public
      # @param [PactBroker::Matrix::ResolvedSelector] resolved_selector
      # @return [Sequel::Dataset] for rows with consumer_id, consumer_name, provider_id and provider_name
      def integrations_for_selector_as_consumer(resolved_selector)
        select(:consumer_id, :provider_id)
          .distinct
          .where({ consumer_id: resolved_selector.pacticipant_id, consumer_version_id: resolved_selector.pacticipant_version_id }.compact)
          .from_self(alias: :integrations)
          .select(:consumer_id, :provider_id, Sequel[:consumers][:name].as(:consumer_name), Sequel[:providers][:name].as(:provider_name))
          .join_consumers(:integrations, :consumers)
          .join_providers(:integrations, :providers)
      end

      # Find all the integrations (consumer/provider pairs) that involve ONLY the given selectors.
      # @public
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_selectors
      # @return [Sequel::Dataset] for rows with consumer_id, consumer_name, provider_id and provider_name
      def distinct_integrations_between_given_selectors(resolved_selectors)
        if resolved_selectors.size == 1
          raise ArgumentError.new("Expected multiple selectors to be provided, but only received one #{selectors}")
        end
        query = pact_publications_matching_selectors_as_consumer(resolved_selectors, pact_columns: :select_distinct_pacticipant_ids)
                  .select_pacticipant_ids
                  .distinct

        query.from_self(alias: :pacticipant_ids)
          .select(
            :consumer_id,
            Sequel[:c][:name].as(:consumer_name),
            :provider_id,
            Sequel[:p][:name].as(:provider_name)
          )
          .join_consumers(:pacticipant_ids, :c)
          .join_providers(:pacticipant_ids, :p)
      end
    end
  end
end
