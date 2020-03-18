require 'pact_broker/matrix/quick_row'

module PactBroker
  module Matrix
    class EveryRow < PactBroker::Matrix::QuickRow
      set_dataset(Sequel.as(:pact_publications, :p))

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

      ALL_COLUMNS = PACT_COLUMNS + VERIFICATION_COLUMNS

      SELECT_ALL_COLUMN_ARGS = [:select_all_columns] + ALL_COLUMNS
      dataset_module do
        select *SELECT_ALL_COLUMN_ARGS

        def join_verifications
          left_outer_join(:verifications, P_V_JOIN, { table_alias: :v } )
        end

        def verifications_for(query_ids)
          db[:verifications]
            .select(:id, :pact_version_id, :provider_id, :provider_version_id, :created_at)
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
