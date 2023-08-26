require "pact_broker/dataset"
require "pact_broker/logging"
require "pact_broker/pacts/pact_version"
require "pact_broker/domain/pacticipant"
require "pact_broker/domain/version"
require "pact_broker/domain/verification"
require "pact_broker/pacts/pact_publication"
require "pact_broker/tags/tag_with_latest_flag"
require "pact_broker/matrix/integration_dataset_module"

# The PactBroker::Matrix::QuickRow represents a row in the table that is created when
# the consumer versions are joined to the provider versions via the pacts and verifications tables,
# aka "The Matrix". The difference between this class and the EveryRow class is that
# the EveryRow class includes results for overridden pact verisons and verifications (used only when there is no latestby
# set in the matrix query), where as the QuickRow class does not.
# It is called the QuickRow because the initial implementation was called the Row, and this is an optimised
# version. It needs to be renamed back to Row now that the old Row class has been deleted.

module PactBroker
  module Matrix
    # TODO rename this to just Row
    # rubocop: disable Metrics/ClassLength

    class QuickRow < Sequel::Model(Sequel.as(:latest_pact_publication_ids_for_consumer_versions, :p))
      # Tables
      LV = :latest_verification_id_for_pact_version_and_provider_version
      LP = :latest_pact_publication_ids_for_consumer_versions

      # Joins
      LP_LV_JOIN = { Sequel[:p][:pact_version_id] => Sequel[:v][:pact_version_id] }
      CONSUMER_VERSION_JOIN = { Sequel[:p][:consumer_version_id] => Sequel[:cv][:id] }
      PROVIDER_VERSION_JOIN = { Sequel[:v][:provider_version_id] => Sequel[:pv][:id] }

      PACT_COLUMNS = [
        Sequel[:p][:consumer_id],
        Sequel[:p][:provider_id],
        Sequel[:p][:consumer_version_id],
        Sequel[:p][:pact_publication_id],
        Sequel[:p][:pact_version_id],
        Sequel[:p][:created_at].as(:consumer_version_created_at),
        Sequel[:p][:pact_publication_id].as(:pact_order)
      ]
      VERIFICATION_COLUMNS = [
        Sequel[:v][:provider_version_id],
        Sequel[:v][:verification_id],
        Sequel[:v][:created_at].as(:provider_version_created_at)
      ]

      JOINED_VERIFICATION_COLUMNS = [
        :verification_id,
        :provider_version_id,
        :pact_version_id,
        :provider_id,
        :created_at
      ]

      LAST_ACTION_DATE = Sequel.lit("CASE WHEN (provider_version_created_at IS NOT NULL AND provider_version_created_at > consumer_version_created_at) THEN provider_version_created_at ELSE consumer_version_created_at END").as(:last_action_date)

      ALL_COLUMNS = PACT_COLUMNS + VERIFICATION_COLUMNS

      # cacheable select arguments
      SELECT_ALL_COLUMN_ARGS = [:select_all_columns] + ALL_COLUMNS
      SELECT_PACTICIPANT_IDS_ARGS = [:select_pacticipant_ids, Sequel[:p][:consumer_id], Sequel[:p][:provider_id]]
      SELECT_PACT_COLUMNS_ARGS = [:select_pact_columns] + PACT_COLUMNS

      EAGER_LOADED_RELATIONSHIPS_FOR_VERSION = { current_deployed_versions: :environment, current_supported_released_versions: :environment, branch_versions: [:branch_head, :version, branch: :pacticipant] }

      associate(:many_to_one, :pact_publication, :class => "PactBroker::Pacts::PactPublication", :key => :pact_publication_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      associate(:many_to_one, :consumer_version, :class => "PactBroker::Domain::Version", :key => :consumer_version_id, :primary_key => :id)
      associate(:many_to_one, :provider_version, :class => "PactBroker::Domain::Version", :key => :provider_version_id, :primary_key => :id)
      associate(:many_to_one, :pact_version, class: "PactBroker::Pacts::PactVersion", :key => :pact_version_id, :primary_key => :id)
      associate(:many_to_one, :verification, class: "PactBroker::Domain::Verification", :key => :verification_id, :primary_key => :id)
      associate(:one_to_many, :consumer_version_tags, :class => "PactBroker::Tags::TagWithLatestFlag", primary_key: :consumer_version_id, key: :version_id)
      associate(:one_to_many, :provider_version_tags, :class => "PactBroker::Tags::TagWithLatestFlag", primary_key: :provider_version_id, key: :version_id)

      class Verification < Sequel::Model(Sequel.as(:latest_verification_id_for_pact_version_and_provider_version, :v))
        dataset_module do
          # declaring the selects this way makes them cacheable
          select(*[:select_verification_columns, *QuickRow::VERIFICATION_COLUMNS, Sequel[:v][:pact_version_id]])

          select(
            :select_verification_columns_2,
            Sequel[:verification_id],
            Sequel[:provider_version_id],
            Sequel[:created_at],
            Sequel[:pact_version_id]
          )

          # @param [Array<PactBroker::Matrix::ResolvedSelector>] selectors
          # @param [Symbol] verifications_columns the method to call on the QuickRow::Verifications/EveryRow::Verifications model to get the right columns required for the particular query
          # @return [Sequel::Dataset<QuickRow>]
          def matching_selectors_as_provider(resolved_selectors)
            # get the UnresolvedSelector objects back out of the resolved_selectors because the Version.for_selector() method uses the UnresolvedSelector
            pacticipant_ids = resolved_selectors.collect(&:pacticipant_id).uniq
            self
              .inner_join_versions_for_selectors_as_provider(resolved_selectors)
              .where(consumer_id: pacticipant_ids)
          end

          def inner_join_versions_for_selectors_as_provider(resolved_selectors)
            # get the UnresolvedSelector objects back out of the resolved_selectors because the Version.for_selector() method uses the UnresolvedSelector
            unresolved_selectors = resolved_selectors.collect(&:original_selector).uniq
            versions = PactBroker::Domain::Version.ids_for_selectors(unresolved_selectors)
            join_versions_dataset(versions)
          end

          def join_versions_dataset(versions_dataset)
            join(versions_dataset, { Sequel[self.model.table_name][:provider_version_id] => Sequel[:versions][:id] }, table_alias: :versions)
          end
        end
      end

      dataset_module do
        include PactBroker::Dataset
        include PactBroker::Matrix::IntegrationDatasetModule

        select(*SELECT_ALL_COLUMN_ARGS)
        select(*SELECT_PACT_COLUMNS_ARGS)
        select(*SELECT_PACTICIPANT_IDS_ARGS)
        select(:select_pacticipant_and_pact_version_ids, Sequel[:p][:consumer_id], Sequel[:p][:provider_id], Sequel[:p][:pact_version_id])

        # The matrix query used to determine the final dataset
        # @param [Array<PactBroker::Matrix::ResolvedSelector>] selectors
        def matching_selectors selectors
          if selectors.size == 1
            select_all_columns
              .matching_one_selector_for_either_consumer_or_provider(selectors)
          else
            matching_only_selectors_joining_verifications(
              selectors,
              pact_columns: :select_pact_columns,
              verifications_columns: :select_verification_columns)
          end
        end

        def order_by_last_action_date
          from_self(alias: :unordered_rows).select(LAST_ACTION_DATE, Sequel[:unordered_rows].* ).order(Sequel.desc(:last_action_date), Sequel.desc(:pact_order), Sequel.desc(:verification_id))
        end

        # eager load tags?
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

        def default_scope
          select_all_columns.left_outer_join_verifications.from_self
        end

        # PRIVATE METHODS

        # Final matrix query with one selector (not the normal use case)
        # When we have one selector, we need to join ALL the verifications to find out
        # what integrations exist
        def matching_one_selector_for_either_consumer_or_provider(resolved_selectors)
          if resolved_selectors.size != 1
            raise ArgumentError.new("Expected one selector to be provided, but received #{resolved_selectors.size}:  #{resolved_selectors}")
          end

          rows_where_selector_matches_consumer = inner_join_versions_for_selectors_as_consumer(resolved_selectors).left_outer_join_verifications
          verifications_matching_provider = verification_model.select_verification_columns_2.inner_join_versions_for_selectors_as_provider(resolved_selectors)
          rows_where_selector_matches_provider = join(verifications_matching_provider, LP_LV_JOIN, { table_alias: :v } )
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
        # @param [Array<PactBroker::Matrix::ResolvedSelector>] selectors
        # @param [Symbol] pact_columns the method to call on the QuickRow/EveryRow model to get the right columns required for the particular query
        # @param [Symbol] verifications_columns the method to call on the QuickRow::Verifications/EveryRow::Verifications model to get the right columns required for the particular query
        # @return [Sequel::Dataset<QuickRow>]
        def matching_only_selectors_joining_verifications(selectors, pact_columns:, verifications_columns: )
          pact_publications = pact_publications_matching_selectors_as_consumer(selectors, pact_columns: pact_columns).from_self(alias: :p)
          verifications = verification_model.select_verification_columns.matching_selectors_as_provider(selectors)
          specified_pacticipant_ids = selectors.select(&:specified?).collect(&:pacticipant_id).uniq

          pact_publications
            .left_outer_join(verifications, { Sequel[:p][:pact_version_id] => Sequel[:v][:pact_version_id] }, { table_alias: :v })
            .where(consumer_id: specified_pacticipant_ids).or(provider_id: specified_pacticipant_ids)
        end

        # Return pact publications where the consumer version is described by any of the resolved_selectors, AND the provider is described by any of the resolved selectors.
        # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_selectors
        # @param [Symbol] pact_columns the method to call on the Model class to get the right columns required for the particular query
        # @return [Sequel::Dataset<QuickRow>]
        def pact_publications_matching_selectors_as_consumer(resolved_selectors, pact_columns:)
          pacticipant_ids = resolved_selectors.collect(&:pacticipant_id).uniq

          self
            .send(pact_columns)
            .inner_join_versions_for_selectors_as_consumer(resolved_selectors)
            .where(provider_id: pacticipant_ids)
        end

        def inner_join_versions_for_selectors_as_consumer(resolved_selectors)
          # get the UnresolvedSelector objects back out of the resolved_selectors because the Version.for_selector() method uses the UnresolvedSelector
          unresolved_selectors = resolved_selectors.collect(&:original_selector).uniq
          versions = PactBroker::Domain::Version.ids_for_selectors(unresolved_selectors)
          inner_join_versions_dataset(versions)
        end

        def inner_join_versions_dataset(versions)
          versions_join = { Sequel[:p][:consumer_version_id] => Sequel[:versions][:id] }
          join(versions, versions_join, table_alias: :versions)
        end

        # Allow this to be overriden in EveryRow
        def verification_model
          QuickRow::Verification
        end

        def join_consumers qualifier = :p, table_alias = :consumers
          join(
            :pacticipants,
            { Sequel[qualifier][:consumer_id] => Sequel[table_alias][:id] },
            { table_alias: table_alias }
          )
        end

        def join_providers qualifier = :p, table_alias = :providers
          join(
            :pacticipants,
            { Sequel[qualifier][:provider_id] => Sequel[table_alias][:id] },
            { table_alias: table_alias }
          )
        end

        def left_outer_join_verifications
          left_outer_join(LV, LP_LV_JOIN, { table_alias: :v } )
        end
      end # end dataset_module

      def pact_version_sha
        pact_version.sha
      end

      def pact_revision_number
        pact_publication.revision_number
      end

      def verification_number
        verification&.number
      end

      def success
        verification&.success
      end

      def pact_created_at
        pact_publication.created_at
      end

      def verification_executed_at
        verification&.execution_date
      end

      # Add logic for ignoring case
      def <=> other
        comparisons = [
          compare_name_asc(consumer_name, other.consumer_name),
          compare_number_desc(consumer_version_order, other.consumer_version_order),
          compare_number_desc(pact_revision_number, other.pact_revision_number),
          compare_name_asc(provider_name, other.provider_name),
          compare_number_desc(provider_version_order, other.provider_version_order),
          compare_number_desc(verification_id, other.verification_id)
        ]

        comparisons.find{|c| c != 0 } || 0
      end

      def compare_name_asc name1, name2
        name1 <=> name2
      end

      def to_s
        "#{consumer_name} v#{consumer_version_number} #{provider_name} #{provider_version_number} #{success}"
      end

      def compare_number_desc number1, number2
        if number1 && number2
          number2 <=> number1
        elsif number1
          1
        else
          -1
        end
      end

      def eql?(obj)
        (obj.class == model) && (obj.values == values)
      end

      def pacticipant_names
        [consumer_name, provider_name]
      end

      def involves_pacticipant_with_name?(pacticipant_name)
        pacticipant_name.include?(pacticipant_name)
      end

      def provider_version_id
        # null when not verified
        values[:provider_version_id]
      end

      def verification_id
        # null when not verified
        return_or_raise_if_not_set(:verification_id)
      end

      def consumer_name
        consumer.name
      end

      def consumer_version_number
        consumer_version.number
      end

      def consumer_version_branch_versions
        consumer_version.branch_versions
      end

      def consumer_version_deployed_versions
        consumer_version.current_deployed_versions
      end

      def consumer_version_released_versions
        consumer_version.current_supported_released_versions
      end

      def consumer_version_order
        consumer_version.order
      end

      def provider_name
        provider.name
      end

      def provider_version_number
        provider_version&.number
      end

      def provider_version_branch_versions
        provider_version&.branch_versions || []
      end

      def provider_version_deployed_versions
        provider_version&.current_deployed_versions || []
      end

      def provider_version_released_versions
        provider_version&.current_supported_released_versions || []
      end

      def provider_version_order
        provider_version&.order
      end

      def last_action_date
        return_or_raise_if_not_set(:last_action_date)
      end

      def has_verification?
        !!verification_id
      end

      # This model needs the verifications and pacticipants joined to it
      # before it can be used, as it's not a "real" model.
      def return_or_raise_if_not_set(key)
        if values.key?(key)
          values[key]
        else
          raise "Required table not joined"
        end
      end
    end
    # rubocop: enable Metrics/ClassLength
  end
end
