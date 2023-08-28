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
        # get the UnresolvedSelector objects back out of the resolved_selectors because the Version.for_selector() method uses the UnresolvedSelector
        pacticipant_ids = resolved_selectors.collect(&:pacticipant_id).uniq
        select_verification_columns_with_aliases
          .inner_join_versions_for_selectors_as_provider(resolved_selectors)
          .where(consumer_id: pacticipant_ids)
      end

      # @private
      def inner_join_versions_for_selectors_as_provider(resolved_selectors)
        # get the UnresolvedSelector objects back out of the resolved_selectors because the Version.for_selector() method uses the UnresolvedSelector
        unresolved_selectors = resolved_selectors.collect(&:original_selector).uniq
        versions = PactBroker::Domain::Version.ids_for_selectors(unresolved_selectors)
        join_versions_dataset(versions)
      end

      # @private
      def join_versions_dataset(versions_dataset)
        join(versions_dataset, { Sequel[self.model.table_name][:provider_version_id] => Sequel[:versions][:id] }, table_alias: :versions)
      end
    end
  end
end
