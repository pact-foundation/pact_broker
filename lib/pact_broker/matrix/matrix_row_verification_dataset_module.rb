#
# The dataset methods to be included in the MatrixRow::Verification dataset module
# and the EveryRow::Verification dataset module.
# Expects the method `select_verification_columns_with_aliases` to be defined on the class
#
module PactBroker
  module Matrix
    module MatrixRowVerificationDatasetModule
      # Verifications for the provider versions matching the given selectors, where the consumers match the pacticipants in the given selectors.
      # @public
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] selectors
      # @return [Sequel::Dataset<MatrixRow>]
      def matching_only_selectors_as_provider(resolved_selectors)
        [
          matching_only_selectors_as_provider_where_only_pacticipant_name_in_selector(resolved_selectors),
          matching_only_selectors_as_provider_where_not_only_pacticipant_name_in_selector(resolved_selectors)
        ].compact.reduce(&:union)
      end

      # @public
      # @return [Sequel::Dataset<Verification>, nil]
      def matching_selectors_as_provider_for_any_consumer(resolved_selectors)
        select_verification_columns_with_aliases
          .where_provider_version_matches_selectors(resolved_selectors)
      end

      # Return verifications where the provider is described by any of the resolved_selectors *that only specify the pacticipant NAME*,
      # AND the consumer is described by any of the resolved selectors.
      # If the original selector only specified the pacticipant name, we don't need to join to the versions table to identify the required verifications.
      # Return nil if there are no resolved selectors where only the pacticipant name is specified.
      # @private
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_selectors
      # @return [Sequel::Dataset<Verification>, nil]
      def matching_only_selectors_as_provider_where_only_pacticipant_name_in_selector(resolved_selectors)
        all_pacticipant_ids = resolved_selectors.collect(&:pacticipant_id).uniq
        pacticipant_ids_for_pacticipant_only_selectors = resolved_selectors.select(&:only_pacticipant_name_specified?).collect(&:pacticipant_id).uniq

        if pacticipant_ids_for_pacticipant_only_selectors.any?
          select_verification_columns_with_aliases
            .where(provider_id: pacticipant_ids_for_pacticipant_only_selectors)
            .where(consumer_id: all_pacticipant_ids)
        end
      end

      # Return verifications where the provider *version* is described by any of the resolved_selectors
      # *that specify more than just the pacticipant name*,
      # AND the consumer is described by any of the resolved selectors.
      # If the selector uses any of the tag/branch/environment/latest attributes, we need to join to the versions table to identify the required verifications.
      # Return nil if there are no resolved selectors where anything other than the pacticipant name is specified.
      # @private
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_selectors
      # @return [Sequel::Dataset<Verification>, nil]
      def matching_only_selectors_as_provider_where_not_only_pacticipant_name_in_selector(resolved_selectors)
        all_pacticipant_ids = resolved_selectors.collect(&:pacticipant_id).uniq
        resolved_selectors_with_versions_specified = resolved_selectors.reject(&:only_pacticipant_name_specified?)

        if resolved_selectors_with_versions_specified.any?
          select_verification_columns_with_aliases
            .where_provider_version_matches_selectors(resolved_selectors_with_versions_specified)
            .where(consumer_id: all_pacticipant_ids)
        end
      end

      # Name-only selectors carry no version id — matching_selectors_as_provider_for_any_consumer
      # passes its selectors unfiltered — so they filter on the provider pacticipant instead. That
      # identifies the same rows, because a verification's provider_id is the
      # pacticipant_id of its provider_version.
      # @private
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_selectors
      # @return [Sequel::Dataset<Verification>]
      def where_provider_version_matches_selectors(resolved_selectors)
        if resolved_selectors.empty?
          raise ArgumentError.new("resolved_selectors must not be empty")
        end

        criteria = provider_criteria_for_selectors(resolved_selectors)
        where(criteria.size > 1 ? Sequel.|(*criteria) : criteria.first)
      end

      # @private
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_selectors
      # @return [Array<Hash>]
      def provider_criteria_for_selectors(resolved_selectors)
        name_only, with_versions = resolved_selectors.partition(&:only_pacticipant_name_specified?)
        table = self.model.table_name

        criteria = []
        criteria << { Sequel[table][:provider_id] => name_only.collect(&:pacticipant_id).uniq } if name_only.any?
        criteria << { Sequel[table][:provider_version_id] => with_versions.collect(&:pacticipant_version_id).uniq } if with_versions.any?
        criteria
      end
    end
  end
end
