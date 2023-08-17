require "pact_broker/dataset"
require "pact_broker/matrix/query_builder"
require "pact_broker/logging"
require "pact_broker/pacts/pact_version"
require "pact_broker/domain/pacticipant"
require "pact_broker/domain/version"
require "pact_broker/domain/verification"
require "pact_broker/pacts/pact_publication"
require "pact_broker/tags/tag_with_latest_flag"
require "pact_broker/matrix/query_ids"

# The PactBroker::Matrix::QuickRow represents a row in the table that is created when
# the consumer versions are joined to the provider versions via the pacts and verifications tables,
# aka "The Matrix". The difference between this class and the EveryRow class is that
# the EveryRow class includes results for overridden pact verisons and verifications (used only when there is no latestby
# set in the matrix query), where as the QuickRow class does not.
# It is called the QuickRow because the initial implementation was called the Row, and this is an optimised
# version. It needs to be renamed back to Row now that the old Row class has been deleted.

# The difference between `join_verifications_for` and `join_verifications` is that
# the left outer join is done on a pre-filtered dataset in `join_verifications_for`,
# so that we get a row with null verification fields for a pact that has been verified
# by a *different* version of the provider we're interested in,
# rather than being excluded from the dataset altogether.

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


      # cachable select arguments
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
          select(*([:select_verification_columns] + QuickRow::VERIFICATION_COLUMNS + [Sequel[:v][:pact_version_id]]))
          select(:select_pact_version_id, Sequel[:v][:pact_version_id])

          def select_distinct_pact_version_id
            select_pact_version_id.distinct
          end

          def join_versions(versions_dataset)
            join(versions_dataset, { Sequel[:v][:provider_version_id] => Sequel[:versions][:id] }, table_alias: :versions)
          end
        end
      end

      dataset_module do
        include PactBroker::Dataset

        select(*SELECT_ALL_COLUMN_ARGS)
        select(*SELECT_PACT_COLUMNS_ARGS)
        select(*SELECT_PACTICIPANT_IDS_ARGS)
        select(:select_pacticipant_and_pact_version_ids, Sequel[:p][:consumer_id], Sequel[:p][:provider_id], Sequel[:p][:pact_version_id])

        def select_distinct_pacticipant_and_pact_version_ids
          select_pacticipant_and_pact_version_ids.distinct
        end

        # @param [PactBroker::Matrix::ResolvedSelector] selector
        def distinct_integrations_for_selector_as_consumer(selector)
          select(:consumer_id, :provider_id)
            .distinct
            .where({ consumer_id: selector.pacticipant_id, consumer_version_id: selector.pacticipant_version_id }.compact)
            .from_self(alias: :integrations)
            .select(:consumer_id, :provider_id, Sequel[:consumers][:name].as(:consumer_name), Sequel[:providers][:name].as(:provider_name))
            .join_consumers(:integrations, :consumers)
            .join_providers(:integrations, :providers)
        end

        # @param [Array<PactBroker::Matrix::ResolvedSelector>] selectors
        def distinct_integrations(selectors)
          query = if selectors.size == 1
                    pacticipant_ids_matching_one_selector_optimised(selectors)
                  else
                    if selectors.all?(&:only_pacticipant_name_specified?)
                      matching_multiple_selectors_without_joining_verifications(selectors)
                        .select_pacticipant_ids
                        .distinct
                    else
                      matching_multiple_selectors_joining_verifications(
                          selectors,
                          pact_columns: :select_distinct_pacticipant_and_pact_version_ids,
                          verifications_columns: :select_distinct_pact_version_id
                        )
                        .select_pacticipant_ids
                        .distinct
                    end
                  end

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

        # The matrix query used to determine the final dataset
        # @param [Array<PactBroker::Matrix::ResolvedSelector>] selectors
        def matching_selectors selectors
          if selectors.size == 1
            select_all_columns.matching_one_selector(selectors)
          else
            matching_multiple_selectors_joining_verifications(
              selectors,
              pact_columns: :select_pact_columns,
              verifications_columns: :select_verification_columns)
          end
        end

        def order_by_last_action_date
          from_self(alias: :unordered_rows).select(LAST_ACTION_DATE, Sequel[:unordered_rows].* ).order(Sequel.desc(:last_action_date), Sequel.desc(:pact_order), Sequel.desc(:verification_id))
        end

        def order_by_pact_publication_created_at
          order(Sequel.desc(:consumer_version_created_at), Sequel.desc(:pact_order))
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
          select_all_columns.join_verifications.from_self
        end

        # PRIVATE METHODS

        # When we have one selector, we need to join ALL the verifications to find out
        # what integrations exist
        def matching_one_selector(selectors)
          query_ids = QueryIds.from_selectors(selectors)
          rows_where_selector_matches_consumer_cols = join_verifications
            .where {
              QueryBuilder.consumer_or_consumer_version_matches(query_ids, :p)
            }

          rows_where_selector_matches_provider_cols = inner_join_verifications_matching_one_selector_provider_or_provider_version(query_ids)
          rows_where_selector_matches_consumer_cols.union(rows_where_selector_matches_provider_cols)
        end

        def pacticipant_ids_matching_one_selector_optimised(selectors)
          query_ids = QueryIds.from_selectors(selectors)
          distinct_pacticipant_ids_where_consumer_or_consumer_version_matches(query_ids)
            .union(distinct_pacticipant_ids_where_provider_or_provider_version_matches(query_ids), all: true)
        end

        def distinct_pacticipant_ids_where_consumer_or_consumer_version_matches(query_ids)
          select_pacticipant_ids
            .distinct
            .where {
              QueryBuilder.consumer_or_consumer_version_matches(query_ids, :p)
            }
        end

        def distinct_pacticipant_ids_where_provider_or_provider_version_matches(query_ids)
          select_pacticipant_ids
            .distinct
            .inner_join_verifications
            .where {
              QueryBuilder.provider_or_provider_version_matches(query_ids, :v, :v)
            }
        end

        # When the user has specified multiple selectors, we only want to join the verifications for
        # the specified selectors. This is because of the behaviour of the left outer join.
        # Imagine a pact has been verified by a provider version that was NOT specified in the selectors.
        # If we join all the verifications and THEN filter the rows to only show the versions specified
        # in the selectors, we won't get a row for that pact, and hence, we won't
        # know that it hasn't been verified by the provider version we're interested in.
        # Instead, we need to filter the verifications dataset down to only the ones specified in the selectors first,
        # and THEN join them to the pacts, so that we get a row for the pact with null provider version
        # and verification fields.
        # @param [Array<PactBroker::Matrix::ResolvedSelector>] selectors
        def matching_multiple_selectors_joining_verifications(selectors, pact_columns:, verifications_columns: )
          pact_publications = pact_publications_matching_selectors_as_consumer(selectors, pact_columns: pact_columns).from_self(alias: :p)
          verifications = verifications_matching_selectors_as_provider(selectors, verifications_columns: verifications_columns)
          specified_pacticipant_ids = selectors.select(&:specified?).collect(&:pacticipant_id).uniq

          pact_publications
            .left_outer_join(verifications, { Sequel[:p][:pact_version_id] => Sequel[:v][:pact_version_id] }, { table_alias: :v })
            .where(consumer_id: specified_pacticipant_ids).or(provider_id: specified_pacticipant_ids)
        end

        # @param [Array<PactBroker::Matrix::ResolvedSelector>] selectors
        def pact_publications_matching_selectors_as_consumer(selectors, pact_columns:)
          unresolved_selectors = selectors.collect(&:original_selector).uniq
          versions = unresolved_selectors.collect{ | selector | PactBroker::Domain::Version.select(Sequel[:versions][:id]).for_selector(selector).select(:id) }.reduce(&:union)
          pacticipant_ids = selectors.collect(&:pacticipant_id).uniq
          versions_join = { Sequel[:p][:consumer_version_id] => Sequel[:versions][:id] }
          self.model.from_self(alias: :p).send(pact_columns).join(versions, versions_join, table_alias: :versions).where(provider_id: pacticipant_ids)
        end


        # @param [Array<PactBroker::Matrix::ResolvedSelector>] selectors
        def verifications_matching_selectors_as_provider(selectors, verifications_columns: )
          unresolved_selectors = selectors.collect(&:original_selector).uniq
          versions = unresolved_selectors.collect{ | selector | PactBroker::Domain::Version.select(Sequel[:versions][:id]).for_selector(selector).select(:id) }.reduce(&:union)
          pacticipant_ids = selectors.collect(&:pacticipant_id).uniq
          verification_model
            .send(verifications_columns)
            .join_versions(versions)
            .where(consumer_id: pacticipant_ids)
        end


        def verification_model
          QuickRow::Verification
        end

        def matching_multiple_selectors_without_joining_verifications(selectors)
          # There are no versions specified in these selectors, so we can do the whole
          # query based on the consumer/provider IDs, which we have in the pact_publication
          # table without having to do a join.
          query_ids = QueryIds.from_selectors(selectors)
          where {
            Sequel.&(
              QueryBuilder.consumer_or_consumer_version_matches(query_ids, :p),
              QueryBuilder.provider_matches(query_ids, :p),
              QueryBuilder.either_consumer_or_provider_was_specified_in_query(query_ids, :p)
            )
          }
        end

        def matching_any_of_multiple_selectors(selectors)
          query_ids = QueryIds.from_selectors(selectors)
          join_verifications_for(query_ids)
            .where {
              Sequel.&(
                Sequel.|(
                  QueryBuilder.consumer_or_consumer_version_matches(query_ids, :p),
                  QueryBuilder.provider_or_provider_version_matches_or_pact_unverified(query_ids, :v, :p),
                ),
                QueryBuilder.either_consumer_or_provider_was_specified_in_query(query_ids, :p)
              )
            }
        end

        def join_verifications_for(query_ids)
          left_outer_join(verifications_for(query_ids), LP_LV_JOIN, { table_alias: :v } )
        end

        def inner_join_verifications_matching_one_selector_provider_or_provider_version(query_ids)
          verifications = db[LV]
            .select(*JOINED_VERIFICATION_COLUMNS)
            .where {
              QueryBuilder.provider_or_provider_version_matches(query_ids)
            }

          join(verifications, LP_LV_JOIN, { table_alias: :v } )
        end

        def verifications_for(query_ids)
          db[LV]
            .select(*JOINED_VERIFICATION_COLUMNS)
            .where {
              Sequel.&(
                QueryBuilder.consumer_in_pacticipant_ids(query_ids),
                QueryBuilder.provider_or_provider_version_matches(query_ids)
              )
            }
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

        def join_consumer_versions
          join(:versions, CONSUMER_VERSION_JOIN, { table_alias: :cv })
        end

        def join_provider_versions
          left_outer_join(:versions, PROVIDER_VERSION_JOIN, { table_alias: :pv } )
        end

        def join_verifications
          left_outer_join(LV, LP_LV_JOIN, { table_alias: :v } )
        end

        def inner_join_verifications
          join(LV, LP_LV_JOIN, { table_alias: :v } )
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

      def consumer_deets
        "#{consumer_name} v#{consumer_version_number} #{provider_name}"
      end

      def provider_deets
        "#{provider_name} #{provider_version_number} #{success}"
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
