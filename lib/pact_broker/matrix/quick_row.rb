require 'pact_broker/pacts/all_pact_publications'
require 'pact_broker/repositories/helpers'
require 'pact_broker/matrix/query_builder'
require 'sequel'
require 'pact_broker/repositories/helpers'
require 'pact_broker/logging'
require 'pact_broker/pacts/pact_version'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/domain/version'
require 'pact_broker/domain/verification'
require 'pact_broker/pacts/pact_publication'
require 'pact_broker/tags/tag_with_latest_flag'
require 'pact_broker/matrix/query_ids'

# The difference between `join_verifications_for` and `join_verifications` is that
# the left outer join is done on a pre-filtered dataset in `join_verifications_for`,
# so that we get a row with null verification fields for a pact that has been verified
# by a *different* version of the provider we're interested in,
# rather than being excluded from the dataset altogether.

module PactBroker
  module Matrix
    class QuickRow < Sequel::Model(Sequel.as(:latest_pact_publication_ids_for_consumer_versions, :p))

      # Tables
      LV = :latest_verification_id_for_pact_version_and_provider_version
      LP = :latest_pact_publication_ids_for_consumer_versions

      # Joins
      LP_LV_JOIN = { Sequel[:p][:pact_version_id] => Sequel[:v][:pact_version_id] }
      CONSUMER_VERSION_JOIN = { Sequel[:p][:consumer_version_id] => Sequel[:cv][:id] }
      PROVIDER_VERSION_JOIN = { Sequel[:v][:provider_version_id] => Sequel[:pv][:id] }

      # Not sure why we're eager loading some things and including others in the base query :shrug:

      # Columns
      CONSUMER_COLUMNS = [
        Sequel[:p][:consumer_id],
        Sequel[:consumers][:name].as(:consumer_name)
      ]
      PROVIDER_COLUMNS = [
        Sequel[:p][:provider_id],
        Sequel[:providers][:name].as(:provider_name)
      ]
      CONSUMER_VERSION_COLUMNS = [
        Sequel[:p][:consumer_version_id],
        Sequel[:cv][:number].as(:consumer_version_number),
        Sequel[:cv][:order].as(:consumer_version_order)
      ]
      PROVIDER_VERSION_COLUMNS = [
        Sequel[:v][:provider_version_id],
        Sequel[:pv][:number].as(:provider_version_number),
        Sequel[:pv][:order].as(:provider_version_order)
      ]
      PACT_COLUMNS = [
        Sequel[:p][:pact_publication_id],
        Sequel[:p][:pact_version_id]
      ]
      VERIFICATION_COLUMNS = [
        Sequel[:v][:verification_id]
      ]
      ALL_COLUMNS = CONSUMER_COLUMNS + CONSUMER_VERSION_COLUMNS + PACT_COLUMNS +
                    PROVIDER_COLUMNS + PROVIDER_VERSION_COLUMNS + VERIFICATION_COLUMNS


      # cachable select arguments
      SELECT_ALL_COLUMN_ARGS = [:select_all_columns] + ALL_COLUMNS
      SELECT_PACTICIPANT_IDS_ARGS = [:select_pacticipant_ids, Sequel[:p][:consumer_id], Sequel[:p][:provider_id]]

      associate(:many_to_one, :pact_publication, :class => "PactBroker::Pacts::PactPublication", :key => :pact_publication_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      associate(:many_to_one, :consumer_version, :class => "PactBroker::Domain::Version", :key => :consumer_version_id, :primary_key => :id)
      associate(:many_to_one, :provider_version, :class => "PactBroker::Domain::Version", :key => :provider_version_id, :primary_key => :id)
      associate(:many_to_one, :pact_version, class: "PactBroker::Pacts::PactVersion", :key => :pact_version_id, :primary_key => :id)
      associate(:many_to_one, :verification, class: "PactBroker::Domain::Verification", :key => :verification_id, :primary_key => :id)
      associate(:one_to_many, :consumer_version_tags, :class => "PactBroker::Tags::TagWithLatestFlag", primary_key: :consumer_version_id, key: :version_id)
      associate(:one_to_many, :provider_version_tags, :class => "PactBroker::Tags::TagWithLatestFlag", primary_key: :provider_version_id, key: :version_id)

      dataset_module do
        include PactBroker::Repositories::Helpers

        select *SELECT_ALL_COLUMN_ARGS
        select *SELECT_PACTICIPANT_IDS_ARGS

        def distinct_integrations selectors, infer_integrations
          query = if selectors.size == 1
            pacticipant_ids_matching_one_selector_optimised(selectors)
          else
            if infer_integrations
              select_pacticipant_ids
                .distinct
                .matching_any_of_multiple_selectors(selectors)
            else
              select_pacticipant_ids
                .distinct
                .matching_multiple_selectors(selectors)
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

        def matching_selectors selectors
          if selectors.size == 1
            matching_one_selector(selectors)
          else
            matching_multiple_selectors(selectors)
          end
        end

        def order_by_names_ascending_most_recent_first
          from_self.
          order(
            Sequel.asc(:consumer_name),
            Sequel.desc(:consumer_version_order),
            Sequel.asc(:provider_name),
            Sequel.desc(:provider_version_order),
            Sequel.desc(:verification_id))
        end

        def eager_all_the_things
          eager(:consumer)
          .eager(:provider)
          .eager(:consumer_version)
          .eager(:provider_version)
          .eager(:verification)
          .eager(:pact_publication)
          .eager(:pact_version)
          .eager(:consumer_version_tags)
          .eager(:provider_version_tags)
        end

        def default_scope
          select_all_columns.join_verifications.join_pacticipants_and_pacticipant_versions.from_self
        end

        # PRIVATE METHODS

        # When we have one selector, we need to join ALL the verifications to find out
        # what integrations exist
        def matching_one_selector(selectors)
          join_verifications
            .join_pacticipants_and_pacticipant_versions
            .where {
              QueryBuilder.consumer_or_consumer_version_or_provider_or_provider_or_provider_version_match(QueryIds.from_selectors(selectors))
            }
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
              QueryBuilder.provider_or_provider_version_matches(query_ids, :v)
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
        def matching_multiple_selectors(selectors)
          query_ids = QueryIds.from_selectors(selectors)
          join_verifications_for(query_ids)
            .join_pacticipants_and_pacticipant_versions
            .where {
              Sequel.&(
                QueryBuilder.consumer_or_consumer_version_matches(query_ids, :p),
                QueryBuilder.provider_or_provider_version_matches_or_pact_unverified(query_ids, :v),
                QueryBuilder.either_consumer_or_provider_was_specified_in_query(query_ids, :p)
              )
            }
        end

        def matching_any_of_multiple_selectors(selectors)
          query_ids = QueryIds.from_selectors(selectors)
          join_verifications_for(query_ids)
            .join_pacticipants_and_pacticipant_versions
            .where {
              Sequel.&(
                Sequel.|(
                  QueryBuilder.consumer_or_consumer_version_matches(query_ids, :p),
                  QueryBuilder.provider_or_provider_version_matches_or_pact_unverified(query_ids, :v),
                ),
                QueryBuilder.either_consumer_or_provider_was_specified_in_query(query_ids, :p)
              )
            }
        end

        def join_verifications_for(query_ids)
          left_outer_join(verifications_for(query_ids), LP_LV_JOIN, { table_alias: :v } )
        end

        def verifications_for(query_ids)
          db[LV]
            .select(:verification_id, :provider_version_id, :pact_version_id, :provider_id)
            .where {
              Sequel.&(
                QueryBuilder.consumer_in_pacticipant_ids(query_ids),
                QueryBuilder.provider_or_provider_version_matches(query_ids)
              )
            }
        end

        def join_pacticipants_and_pacticipant_versions
          join_consumers
            .join_providers
            .join_consumer_versions
            .join_provider_versions
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

      def success
        verification&.success
      end

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
        return_or_raise_if_not_set(:consumer_name)
      end

      def consumer_version_number
        return_or_raise_if_not_set(:consumer_version_number)
      end

      def consumer_version_order
        return_or_raise_if_not_set(:consumer_version_order)
      end

      def provider_name
        return_or_raise_if_not_set(:provider_name)
      end

      def provider_version_number
        return_or_raise_if_not_set(:provider_version_number)
      end

      def provider_version_order
        return_or_raise_if_not_set(:provider_version_order)
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
  end
end
