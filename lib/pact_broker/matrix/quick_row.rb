=begin
The Matrix::Row is based on the matrix view which does a join of every pact/verification
and then selects the relevant ones.

The Matrix::QuickRow starts with the relevant rows, and builds the matrix query from that,
making it much quicker.

=end
require 'sequel'
require 'pact_broker/repositories/helpers'
require 'pact_broker/logging'
require 'pact_broker/pacts/pact_version'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/domain/version'
require 'pact_broker/domain/verification'
require 'pact_broker/pacts/pact_publication'
require 'pact_broker/tags/tag_with_latest_flag'

module PactBroker
  module Matrix
    LV = :latest_verification_id_for_pact_version_and_provider_version
    LP = :latest_pact_publication_ids_for_consumer_versions

    CONSUMER_COLUMNS = [Sequel[:lp][:consumer_id], Sequel[:consumers][:name].as(:consumer_name), Sequel[:lp][:pact_publication_id], Sequel[:lp][:pact_version_id]]
    PROVIDER_COLUMNS = [Sequel[:lp][:provider_id], Sequel[:providers][:name].as(:provider_name), Sequel[:lv][:verification_id]]
    CONSUMER_VERSION_COLUMNS = [Sequel[:lp][:consumer_version_id], Sequel[:cv][:number].as(:consumer_version_number), Sequel[:cv][:order].as(:consumer_version_order)]
    PROVIDER_VERSION_COLUMNS = [Sequel[:lv][:provider_version_id], Sequel[:pv][:number].as(:provider_version_number), Sequel[:pv][:order].as(:provider_version_order)]
    ALL_COLUMNS = CONSUMER_COLUMNS + CONSUMER_VERSION_COLUMNS + PROVIDER_COLUMNS + PROVIDER_VERSION_COLUMNS

    LP_LV_JOIN = { Sequel[:lp][:pact_version_id] => Sequel[:lv][:pact_version_id] }
    CONSUMER_JOIN = { Sequel[:lp][:consumer_id] => Sequel[:consumers][:id] }
    PROVIDER_JOIN = { Sequel[:lp][:provider_id] => Sequel[:providers][:id] }
    CONSUMER_VERSION_JOIN = { Sequel[:lp][:consumer_version_id] => Sequel[:cv][:id] }
    PROVIDER_VERSION_JOIN = { Sequel[:lv][:provider_version_id] => Sequel[:pv][:id] }

    RAW_QUERY = Sequel::Model.db[Sequel.as(LP, :lp)]
      .select(*ALL_COLUMNS)
      .left_outer_join(LV, LP_LV_JOIN, { table_alias: :lv } )
      .join(:pacticipants, CONSUMER_JOIN, { table_alias: :consumers })
      .join(:pacticipants, PROVIDER_JOIN, { table_alias: :providers })
      .join(:versions, CONSUMER_VERSION_JOIN, { table_alias: :cv })
      .left_outer_join(:versions, PROVIDER_VERSION_JOIN, { table_alias: :pv } )

    ALIASED_QUERY = Sequel.as(RAW_QUERY, :quick_rows)

    class QuickRow < Sequel::Model(ALIASED_QUERY)
      CONSUMER_ID = Sequel[:quick_rows][:consumer_id]
      PROVIDER_ID = Sequel[:quick_rows][:provider_id]
      CONSUMER_VERSION_ID = Sequel[:quick_rows][:consumer_version_id]
      PROVIDER_VERSION_ID = Sequel[:quick_rows][:provider_version_id]
      PACT_PUBLICATION_ID = Sequel[:quick_rows][:pact_publication_id]
      VERIFICATION_ID = Sequel[:quick_rows][:verification_id]

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
        include PactBroker::Logging

        select :pacticipant_names_and_ids, :consumer_name, :consumer_id, :provider_name, :provider_id

        def consumer_id consumer_id
          where(CONSUMER_ID => consumer_id)
        end

        def matching_selectors selectors
          if selectors.size == 1
            where_consumer_or_provider_is(selectors.first)
          else
            where_consumer_and_provider_in(selectors)
          end
        end

        # find rows where (the consumer (and optional version) matches any of the selectors)
        # AND
        # the (provider (and optional version) matches any of the selectors OR the provider matches
        #      and the verification is missing (and hence the provider version is null))
        def where_consumer_and_provider_in selectors
          where{
            QueryHelper.consumer_and_provider_in(selectors)
          }
        end

        def where_consumer_or_provider_is s
          where{
            QueryHelper.consumer_or_consumer_version_or_provider_or_provider_or_provider_version_match_selector(s)
          }
        end

        # Can't access other dataset_module methods from inside the Sequel `where{ ... }` block, so make a private class
        # with some helper methods
        class QueryHelper
          def self.consumer_and_provider_in selectors
            Sequel.&(
              Sequel.|(
                *consumer_and_maybe_consumer_version_match_any_selector(selectors)
              ),
              Sequel.|(
                *provider_and_maybe_provider_version_match_any_selector_or_verification_is_missing(selectors)
              ),
              either_consumer_or_provider_was_specified_in_query(selectors)
            )
          end

          def self.consumer_and_maybe_consumer_version_match_any_selector(selectors)
            selectors.collect { |s| consumer_and_maybe_consumer_version_match_selector(s) }
          end

          def self.consumer_and_maybe_consumer_version_match_selector(s)
            if s[:pact_publication_ids]
              { PACT_PUBLICATION_ID => s[:pact_publication_ids] }
            elsif s[:pacticipant_version_id]
              { CONSUMER_ID => s[:pacticipant_id], CONSUMER_VERSION_ID => s[:pacticipant_version_id] }
            else
              { CONSUMER_ID => s[:pacticipant_id] }
            end
          end

          def self.provider_and_maybe_provider_version_match_selector(s)
            if s[:verification_ids]
              { VERIFICATION_ID => s[:verification_ids] }
            elsif s[:pacticipant_version_id]
              { PROVIDER_ID => s[:pacticipant_id], PROVIDER_VERSION_ID => s[:pacticipant_version_id] }
            else
              { PROVIDER_ID => s[:pacticipant_id] }
            end
          end

          # if the pact for a consumer version has never been verified, it exists in the matrix as a row
          # with a blank provider version id
          def self.provider_verification_is_missing_for_matching_selector(s)
            { PROVIDER_ID => s[:pacticipant_id], PROVIDER_VERSION_ID => nil }
          end

          def self.provider_and_maybe_provider_version_match_any_selector_or_verification_is_missing(selectors)
            selectors.collect { |s|
              provider_and_maybe_provider_version_match_selector(s)
            } + selectors.collect { |s|
              provider_verification_is_missing_for_matching_selector(s)
            }
          end

          # Some selecters are specified in the query, others are implied (when only one pacticipant is specified,
          # the integrations are automatically worked out, and the selectors for these are of type :implied )
          # When there are 3 pacticipants that each have dependencies on each other (A->B, A->C, B->C), the query
          # to deploy C (implied A, implied B, specified C) was returning the A->B row because it matched the
          # implied selectors as well.
          # This extra filter makes sure that every row that is returned actually matches one of the specified
          # selectors.
          def self.either_consumer_or_provider_was_specified_in_query(selectors)
            specified_pacticipant_ids = selectors.select{ |s| s[:type] == :specified }.collect{ |s| s[:pacticipant_id] }
            Sequel.|({ CONSUMER_ID => specified_pacticipant_ids } , { PROVIDER_ID => specified_pacticipant_ids })
          end

          def self.consumer_or_consumer_version_or_provider_or_provider_or_provider_version_match_selector(s)
            Sequel.|(
              s[:pacticipant_version_id] ? { CONSUMER_VERSION_ID => s[:pacticipant_version_id] } :  { CONSUMER_ID => s[:pacticipant_id] },
              s[:pacticipant_version_id] ? { PROVIDER_VERSION_ID => s[:pacticipant_version_id] } :  { PROVIDER_ID => s[:pacticipant_id] }
            )
          end
        end

        def order_by_names_ascending_most_recent_first
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
        end

      end

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
    end
  end
end
