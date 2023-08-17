require "pact_broker/matrix/quick_row"

module PactBroker
  module Matrix
    class EveryRow < PactBroker::Matrix::QuickRow
      set_dataset(Sequel.as(:pact_publications, :p))

      class Verification < Sequel::Model(:verifications)
        dataset_module do
          select(:select_verification_columns, Sequel[:verifications][:id].as(:verification_id), :provider_version_id, Sequel[:verifications][:created_at].as(:provider_version_created_at), Sequel[:verifications][:pact_version_id])
          select(:select_pact_version_id, Sequel[:verifications][:pact_version_id])

          def select_distinct_pact_version_id
            select_pact_version_id.distinct
          end

          def join_versions(versions_dataset)
            join(versions_dataset, { Sequel[:verifications][:provider_version_id] => Sequel[:versions][:id] }, table_alias: :versions)
          end
        end
      end

      P_V_JOIN = { Sequel[:p][:pact_version_id] => Sequel[:v][:pact_version_id] }

      PACT_COLUMNS = [
        Sequel[:p][:consumer_id],
        Sequel[:p][:provider_id],
        Sequel[:p][:consumer_version_id],
        Sequel[:p][:id].as(:pact_publication_id),
        Sequel[:p][:pact_version_id],
        Sequel[:p][:revision_number].as(:pact_revision_number),
        Sequel[:p][:created_at].as(:consumer_version_created_at),
        Sequel[:p][:id].as(:pact_order)
      ]

      VERIFICATION_COLUMNS = [
        Sequel[:v][:id].as(:verification_id),
        Sequel[:v][:provider_version_id],
        Sequel[:v][:created_at].as(:provider_version_created_at)
      ]

      JOINED_VERIFICATION_COLUMNS = [:id, :pact_version_id, :provider_id, :provider_version_id, :created_at]

      ALL_COLUMNS = PACT_COLUMNS + VERIFICATION_COLUMNS

      SELECT_ALL_COLUMN_ARGS = [:select_all_columns] + ALL_COLUMNS
      SELECT_PACT_COLUMNS_ARGS = [:select_pact_columns] + PACT_COLUMNS

      dataset_module do
        select(*SELECT_ALL_COLUMN_ARGS)
        select(*SELECT_PACT_COLUMNS_ARGS)

        def join_verifications
          left_outer_join(:verifications, P_V_JOIN, { table_alias: :v } )
        end

        def verification_model
          EveryRow::Verification
        end

        def inner_join_verifications
          join(:verifications, P_V_JOIN, { table_alias: :v } )
        end

        def inner_join_verifications_matching_one_selector_provider_or_provider_version(query_ids)
          verifications = db[:verifications]
            .select(*JOINED_VERIFICATION_COLUMNS)
            .where {
              QueryBuilder.provider_or_provider_version_matches(query_ids)
            }

          join(verifications, P_V_JOIN, { table_alias: :v } )
        end

        def verifications_for(query_ids)
          db[:verifications]
            .select(*JOINED_VERIFICATION_COLUMNS)
            .where {
              Sequel.&(
                QueryBuilder.consumer_in_pacticipant_ids(query_ids),
                QueryBuilder.provider_or_provider_version_matches(query_ids)
              )
            }
        end
      end
    end
  end
end
