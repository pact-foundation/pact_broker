# The dataset methods used by both the MatrixRow and the EveryRow classes
# Requires the following methods to be defined on the model
#   - verification_dataset
#   - select_pact_columns_with_aliases
#   - select_all_columns_after_join

module PactBroker
  module Matrix
    module MatrixRowDatasetModule
      EAGER_LOADED_RELATIONSHIPS_FOR_VERSION = { current_deployed_versions: :environment, current_supported_released_versions: :environment, branch_versions: [:branch_head, :version, branch: :pacticipant] }
      LAST_ACTION_DATE = Sequel.lit("CASE WHEN (provider_version_created_at IS NOT NULL AND provider_version_created_at > consumer_version_created_at) THEN provider_version_created_at ELSE consumer_version_created_at END").as(:last_action_date)

      # The matrix query used to determine the final dataset
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_selectors
      def matching_selectors(resolved_selectors)
        if resolved_selectors.size == 1
          matching_one_selector_for_either_consumer_or_provider(resolved_selectors)
        else
          matching_only_selectors_joining_verifications(resolved_selectors)
        end
      end

      # @public
      def order_by_last_action_date
        from_self(alias: :unordered_rows).select(LAST_ACTION_DATE, Sequel[:unordered_rows].* ).order(Sequel.desc(:last_action_date), Sequel.desc(:pact_order), Sequel.desc(:verification_id))
      end

      # eager load tags?
      # @public
      def eager_all_the_things
        eager(
          :consumer,
          :provider,
          :verification,
          :pact_publication,
          :pact_version,
          consumer_version: EAGER_LOADED_RELATIONSHIPS_FOR_VERSION,
          provider_version: EAGER_LOADED_RELATIONSHIPS_FOR_VERSION,
          consumer_version_tags: { version: :pacticipant },
          provider_version_tags: { version: :pacticipant }
        )
      end

      # Just for testing purposes
      def default_scope
        select_pact_columns_with_aliases
          .from_self(alias: :p)
          .left_outer_join_verifications
          .select_all_columns_after_join
      end

      # PRIVATE METHODS

      # Final matrix query with one selector (not the normal use case)
      # When we have one selector, we need to join ALL the verifications to find out
      # what integrations exist
      # @private
      def matching_one_selector_for_either_consumer_or_provider(resolved_selectors)
        if resolved_selectors.size != 1
          raise ArgumentError.new("Expected one selector to be provided, but received #{resolved_selectors.size}:  #{resolved_selectors}")
        end

        # consumer
        pact_publication_matching_consumer = select_pact_columns_with_aliases.from_self(alias: :p).inner_join_versions_for_selectors_as_consumer(resolved_selectors)
        rows_where_selector_matches_consumer = pact_publication_matching_consumer.left_outer_join_verifications.select_all_columns_after_join

        # provider
        verifications_matching_provider = verification_dataset.matching_selectors_as_provider_for_any_consumer(resolved_selectors)
        rows_where_selector_matches_provider = select_pact_columns_with_aliases.from_self(alias: :p).inner_join_verifications_dataset(verifications_matching_provider).select_all_columns_after_join

        # union
        rows_where_selector_matches_consumer.union(rows_where_selector_matches_provider)
      end

      # Find the matrix rows
      # When the user has specified multiple selectors, we only want to join the verifications for
      # the specified selectors. This is because of the behaviour of the left outer join.
      # Imagine a pact has been verified by a provider version that was NOT specified in the selectors.
      # If we join all the verifications and THEN filter the rows to only show the versions specified
      # in the selectors, we won't get a row for that pact, and hence, we won't
      # know that it hasn't been verified by the provider version we're interested in.
      # Instead, we need to filter the verifications dataset down to only the ones specified in the selectors first,
      # and THEN join them to the pacts, so that we get a row for the pact with null provider version
      # and verification fields.
      # IDEA FOR OPTIMISATION - would it work to limit the pact_publications query and the verifications query to the limit of the overall query?
      # @private
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_selectors
      # @return [Sequel::Dataset<MatrixRow>]
      def matching_only_selectors_joining_verifications(resolved_selectors)
        pact_publications = matching_only_selectors_as_consumer(resolved_selectors)
        verifications = verification_dataset.matching_only_selectors_as_provider(resolved_selectors)

        specified_pacticipant_ids = resolved_selectors.select(&:specified?).collect(&:pacticipant_id).uniq

        pact_publications
          .from_self(alias: :p)
          .select_all_columns_after_join
          .left_outer_join_verifications_dataset(verifications)
          .where(consumer_id: specified_pacticipant_ids).or(provider_id: specified_pacticipant_ids)
      end

      # Return pact publications where the consumer/consumer version is described by any of the resolved_selectors, AND the provider is described by any of the resolved selectors.
      # @private
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_selectors
      # @return [Sequel::Dataset<MatrixRow>]
      def matching_only_selectors_as_consumer(resolved_selectors)
        [
          matching_only_selectors_as_consumer_where_only_pacticipant_name_in_selector(resolved_selectors),
          matching_only_selectors_as_consumer_where_not_only_pacticipant_name_in_selector(resolved_selectors),
        ].compact.reduce(&:union)
      end


      # Return pact publications where the consumer is described by any of the resolved_selectors *that only specify the pacticipant NAME*, AND the provider is described by any of the resolved selectors.
      # If the original selector only specified the pacticipant name, we don't need to join to the versions table to identify the required pact_publications.
      # Return nil if there are no resolved selectors where only the pacticipant name is specified.
      # @private
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_selectors
      # @return [Sequel::Dataset<MatrixRow>, nil]
      def matching_only_selectors_as_consumer_where_only_pacticipant_name_in_selector(resolved_selectors)
        all_pacticipant_ids = resolved_selectors.collect(&:pacticipant_id).uniq
        pacticipant_ids_for_pacticipant_only_selectors = resolved_selectors.select(&:only_pacticipant_name_specified?).collect(&:pacticipant_id).uniq

        if pacticipant_ids_for_pacticipant_only_selectors.any?
          select_pact_columns_with_aliases
            .where(consumer_id: pacticipant_ids_for_pacticipant_only_selectors)
            .where(provider_id: all_pacticipant_ids)
        end
      end

      # Return pact publications where the consumer *version* is described by any of the resolved_selectors
      # *that specify more than just the pacticipant name*,
      # AND the provider is described by any of the resolved selectors.
      # If the selector uses any of the tag/branch/environment/latest attributes, we need to join to the versions table to identify the required pact_publications.
      # Return nil if there are no resolved selectors where anything other than the pacticipant name is specified.
      # @private
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_selectors
      # @return [Sequel::Dataset<MatrixRow>, nil]
      def matching_only_selectors_as_consumer_where_not_only_pacticipant_name_in_selector(resolved_selectors)
        all_pacticipant_ids = resolved_selectors.collect(&:pacticipant_id).uniq
        resolved_selectors_with_versions_specified = resolved_selectors.reject(&:only_pacticipant_name_specified?)

        if resolved_selectors_with_versions_specified.any?
          select_pact_columns_with_aliases
            .inner_join_versions_for_selectors_as_consumer(resolved_selectors_with_versions_specified)
            .where(provider_id: all_pacticipant_ids)
        end
      end

      # @private
      def inner_join_versions_for_selectors_as_consumer(resolved_selectors)
        # get the UnresolvedSelector objects back out of the resolved_selectors because the Version.for_selector() method uses the UnresolvedSelector
        unresolved_selectors = resolved_selectors.collect(&:original_selector).uniq
        versions = PactBroker::Domain::Version.ids_for_selectors(unresolved_selectors)
        inner_join_versions_dataset(versions)
      end

      # @private
      def inner_join_versions_dataset(versions)
        versions_join = { Sequel[:p][:consumer_version_id] => Sequel[:versions][:id] }
        join(versions, versions_join, table_alias: :versions)
      end

      # @private
      def left_outer_join_verifications
        left_outer_join_verifications_dataset(verification_dataset.select_verification_columns_with_aliases)
      end

      def left_outer_join_verifications_dataset(verifications)
        left_outer_join(verifications, { Sequel[:p][:pact_version_id] => Sequel[:v][:pact_version_id] }, { table_alias: :v } )
      end

      # @private
      def inner_join_verifications_dataset(verifications_dataset)
        join(verifications_dataset, { Sequel[:p][:pact_version_id] => Sequel[:v][:pact_version_id] }, { table_alias: :v } )
      end
    end
  end
end
