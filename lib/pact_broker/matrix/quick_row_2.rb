require 'pact_broker/pacts/all_pact_publications'
require 'pact_broker/repositories/helpers'
require 'pact_broker/matrix/query_builder'

# The difference between this query and the query for QuickRow2 is that
# the left outer join is done on a pre-filtered dataset so that we
# get a row with null verification fields for a pact that has not been verified
# by the particular providers where're interested in, rather than being excluded
# from the dataset.

module PactBroker
  module Matrix
    class QuickRow2 < Sequel::Model(Sequel.as(:latest_pact_publication_ids_for_consumer_versions, :lp))
      LV = :latest_verification_id_for_pact_version_and_provider_version
      LP = :latest_pact_publication_ids_for_consumer_versions

      LP_LV_JOIN = { Sequel[:lp][:pact_version_id] => Sequel[:lv][:pact_version_id] }
      CONSUMER_JOIN = { Sequel[:lp][:consumer_id] => Sequel[:consumers][:id] }
      PROVIDER_JOIN = { Sequel[:lp][:provider_id] => Sequel[:providers][:id] }
      CONSUMER_VERSION_JOIN = { Sequel[:lp][:consumer_version_id] => Sequel[:cv][:id] }
      PROVIDER_VERSION_JOIN = { Sequel[:lv][:provider_version_id] => Sequel[:pv][:id] }

      CONSUMER_COLUMNS = [Sequel[:lp][:consumer_id], Sequel[:consumers][:name].as(:consumer_name), Sequel[:lp][:pact_publication_id], Sequel[:lp][:pact_version_id]]
      PROVIDER_COLUMNS = [Sequel[:lp][:provider_id], Sequel[:providers][:name].as(:provider_name), Sequel[:lv][:verification_id]]
      CONSUMER_VERSION_COLUMNS = [Sequel[:lp][:consumer_version_id], Sequel[:cv][:number].as(:consumer_version_number), Sequel[:cv][:order].as(:consumer_version_order)]
      PROVIDER_VERSION_COLUMNS = [Sequel[:lv][:provider_version_id], Sequel[:pv][:number].as(:provider_version_number), Sequel[:pv][:order].as(:provider_version_order)]
      ALL_COLUMNS = CONSUMER_COLUMNS + CONSUMER_VERSION_COLUMNS + PROVIDER_COLUMNS + PROVIDER_VERSION_COLUMNS

      SELECT_ALL_COLUMN_ARGS = [:select_all_columns] + ALL_COLUMNS

      dataset_module do
        include PactBroker::Repositories::Helpers

        select *SELECT_ALL_COLUMN_ARGS

        def matching_selectors selectors
          if selectors.size == 1
            matching_one_selector(selectors.first)
          else
            matching_multiple_selectors(selectors)
          end
        end

        # When we have one selector, we need to join ALL the verifications to find out
        # what integrations exist
        def matching_one_selector(selector)
          select_all_columns
            .join_verifications
            .join_pacticipants_and_pacticipant_versions
            .where {
              QueryBuilder.consumer_or_consumer_version_or_provider_or_provider_or_provider_version_match_selector(selector)
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
          select_all_columns
            .join_verifications_for(selectors)
            .join_pacticipants_and_pacticipant_versions
            .where {
              Sequel.&(
                QueryBuilder.consumer_or_consumer_version_or_pact_publication_in(selectors, :lp),
                QueryBuilder.either_consumer_or_provider_was_specified_in_query(selectors, :lp)
              )
            }
            .from_self(alias: :t9)
            .where {
              QueryBuilder.provider_or_provider_version_or_verification_in(selectors, true, :t9)
            }
        end

        def join_pacticipants_and_pacticipant_versions
          join_consumers
            .join_providers
            .join_consumer_versions
            .join_provider_versions
        end

        def join_consumers
          join(:pacticipants, CONSUMER_JOIN, { table_alias: :consumers })
        end

        def join_providers
          join(:pacticipants, PROVIDER_JOIN, { table_alias: :providers })
        end

        def join_consumer_versions
          join(:versions, CONSUMER_VERSION_JOIN, { table_alias: :cv })
        end

        def join_provider_versions
          left_outer_join(:versions, PROVIDER_VERSION_JOIN, { table_alias: :pv } )
        end

        def join_verifications_for(selectors)
          left_outer_join(verifications_for(selectors), LP_LV_JOIN, { table_alias: :lv } )
        end

        def join_verifications
          left_outer_join(LV, LP_LV_JOIN, { table_alias: :lv } )
        end

        def verifications_for(selectors)
          db[LV]
            .select(:verification_id, :provider_version_id, :pact_version_id)
            .where {
              Sequel.&(
                QueryBuilder.consumer_in_pacticipant_ids(selectors),
                QueryBuilder.provider_or_provider_version_or_verification_in(selectors, false, LV)
              )
            }
        end
      end
    end
  end
end
